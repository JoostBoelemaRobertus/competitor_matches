WITH match_table_correct_valid_matches AS (
    SELECT matches.*,
           pn_products.article_id               AS picnic_article_id,
           CASE
               WHEN pn_products.art_content_volume > 0 THEN CAST(
                       pn_products.art_content_volume_uom AS STRING)
               WHEN pn_products.art_content_weight > 0 THEN CAST(
                       pn_products.art_content_weight_uom AS STRING)
               ELSE 'pcs'
               END                              AS picnic_content_uom,
           CASE
               WHEN pn_products.art_content_volume > 0 THEN pn_products.art_content_volume
               WHEN pn_products.art_content_weight > 0 THEN pn_products.art_content_weight
               ELSE pn_products.art_content_pieces
               END                              AS picnic_content_value,
           CASE
               WHEN picnic_content_uom = matches.competitor_article_unit_of_measurement_conversion THEN 1
               WHEN picnic_content_uom = 'pcs' OR
                    matches.competitor_article_unit_of_measurement_conversion = 'pcs' THEN 0
               WHEN picnic_content_uom = 'kilo' OR picnic_content_uom = 'liter' THEN 1000
               ELSE 0.001
               END                              AS factor,
           CASE
               WHEN pn_products.art_store_content_summary =
                    matches.competitor_article_store_content_summary THEN 1
               ELSE (
                            picnic_content_value / nullif(
                                matches.competitor_article_value_conversion, 0)) * factor
               END                              AS content_conversion_factor_corrected,
           NULLIF(CASE
                      WHEN matches.key_date >= '20210127' THEN content_conversion_factor_corrected
                      ELSE match_content_conversion_factor
                      END,
                  0)                            AS used_content_conversion_factor, --start of historic tracking of competitor product properties
           round(
                   CASE
                       WHEN matches.match_overwrite_content_conversion_factor > 0 THEN
                               matches.competitor_article_price_amount *
                               matches.match_overwrite_content_conversion_factor
                       ELSE matches.competitor_article_price_amount * used_content_conversion_factor
                       END,
                   2)                           AS competitor_price_converted_corrected,
           matches.competitor_article_is_active AS competitor_product_active_corrected,
           CASE
               WHEN matches.match_is_approved
                   AND matches.match_type <> 'No match'
                   AND competitor_price_converted_corrected >= 0.01
                   AND competitor_product_active_corrected THEN TRUE
               ELSE FALSE
               END                              AS match_is_valid_correction
    FROM dim.ft_article_competitor_match_daily AS matches
             INNER JOIN dim.dm_article AS pn_products
                        ON matches.key_article = pn_products.key_article
    WHERE matches.match_is_deleted <> 'yes'
),
     used_matches AS (
         SELECT pn_art.article_id                                                                                AS picnic_article_id,
                comp_art.comp_art_supermarket                                                                    AS retailer,
                matches.key_date,
                matches.MATCH_NAME,
                matches.match_type,
                matches.match_is_valid,
                matches.match_is_valid_corrected,
                matches.used_content_conversion_factor                                                           AS match_content_conversion_factor,
                matches.match_overwrite_content_conversion_factor,
                comp_art.competitor_article_id                                                                   AS retailer_id,
                row_number(
                    ) OVER (
                    PARTITION BY picnic_article_id, retailer, matches.key_date ORDER BY matches.match_type DESC) AS match_index --take exact match if available
         FROM match_table_correct_valid_matches AS matches
                  LEFT JOIN dim.dm_competitor_article AS comp_art
                            ON matches.key_competitor_article = comp_art.key_competitor_article
                  LEFT JOIN dim.dm_article AS pn_art
                            ON matches.key_article = pn_art.key_article
                  INNER JOIN dim.DM_DATE AS dt
                             ON matches.KEY_DATE = dt.KEY_DATE
         WHERE dt.date = cast(GETDATE() AS DATE)
     )
SELECT MATCH_NAME,
       picnic_article_id,
       retailer_id As competitor_retailer_id,
              CASE
           WHEN retailer = 'Albert Heijn' THEN 'ah'
           WHEN retailer = 'dm online' THEN 'dm'
           ELSE LOWER(retailer)
           END                  AS competitor_retailer,
       MATCH_TYPE,
       match_is_valid_corrected AS valid_match
FROM used_matches
;
