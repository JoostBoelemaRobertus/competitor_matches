WITH latest_scrape_dates AS (
    SELECT STORE_ID,
           MAX(DATE(LAST_UPDATED)) AS latest_scrape_date
    FROM dim.FT_SUPERSCANNER_ARTICLE_PRICE AS cp_art
    GROUP BY STORE_ID
),
     match_table_correct_valid_matches AS (
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
SELECT cp_art.COMP_ART_SALESFORCE_ID             AS id,
       cp_art.COMP_ART_NAME                      AS name,
       REGEXP_REPLACE(cp_price.LOAD_QUERY_SUPERMARKET, '_de|_fr| online', '') as competitor,
       LOWER(cp_art.COMP_ART_SUPERMARKET),
       cp_art.COMPETITOR_ARTICLE_ID              AS retailer_id,
       matches.MATCH_NAME,
       cp_price.price                            AS latest_selling_price,
       latest_scrape_dates.latest_scrape_date,
       cp_price.main_category                    AS main_category,
       cp_price.sub_category                     AS sub_category,
       cp_price.UNIT_VALUE                       AS uom_amount_standardised,
       cp_price.UNIT_MEASUREMENT                 AS cp_competitor_content_unit__c,
       CASE
           WHEN cp_competitor_content_unit__c = 'g' THEN 'gram'
           ELSE cp_competitor_content_unit__c
           END                                   AS uom_standardised,
       cp_art.COMP_ART_BRAND                     AS brand_name,
       cp_art.COMP_ART_BRAND_TIER                AS brand_tier,
       cp_art.COMP_ART_PACKAGING                 AS packaging,
       CASE
           WHEN packaging = 'doos'
               OR packaging = 'zak'
               OR packaging = 'zakje'
               OR packaging = 'fles'
               OR packaging = 'tray'
               OR packaging = 'pak'
               OR packaging = 'pot'
               OR packaging = 'blik'
               OR packaging = 'beker'
               OR packaging = 'bak'
               OR packaging = 'blister'
               OR packaging = 'tube'
               OR packaging = 'box'
               OR packaging = 'bus'
               OR packaging = 'emmer'
               OR packaging = 'set'
               OR packaging = 'DS'
               OR packaging = 'ZK'
               OR packaging = 'FLS'
               OR packaging = 'TRA'
               OR packaging = 'PAK'
               OR packaging = 'POT'
               OR packaging = 'BLK'
               OR packaging = 'CUP'
               OR packaging = 'BAK'
               OR packaging = 'BLS'
               OR packaging = 'TUB'
               OR packaging = 'BUS'
               THEN packaging
           END                                   AS selected_packaging,
       matched_picnic_products.article_id        AS was_matched_to_article_id,
       matched_picnic_products.ART_SALESFORCE_ID AS was_matched_to_sf_id
FROM dim.DM_COMPETITOR_ARTICLE AS cp_art
         INNER JOIN dim.FT_SUPERSCANNER_ARTICLE_PRICE AS cp_price
                    ON cp_art.COMPETITOR_ARTICLE_ID = cp_price.STORE_ID
         INNER JOIN dim.DM_DATE
                    ON cp_price.KEY_DATE = DM_DATE.KEY_DATE
         INNER JOIN latest_scrape_dates
                    ON cp_art.COMPETITOR_ARTICLE_ID = latest_scrape_dates.STORE_ID
         INNER JOIN used_matches AS matches
                    ON cp_art.COMPETITOR_ARTICLE_ID = matches.retailer_id
         INNER JOIN dim.DM_ARTICLE AS matched_picnic_products
                    ON matches.picnic_article_id = matched_picnic_products.ARTICLE_ID
WHERE DM_DATE.date = CURRENT_DATE()
  AND cp_price.price_line_type = 'default'
  AND latest_scrape_dates.latest_scrape_date BETWEEN DATEADD(DAY, -14, GETDATE()) AND DATEADD(DAY, -7, GETDATE())
  AND matches.match_type <> 'No match'
  AND matched_picnic_products.ART_IN_STORE = 'yes'
;
