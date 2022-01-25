-- Select all active Picnic products
SELECT ART_SALESFORCE_ID                                                                        AS id,
       ARTICLE_ID                                                                               AS article_id,
       ART_PICNIC_NAME                                                                          AS name,
       ART_PICNIC_PRICE_EU                                                                      AS latest_selling_price,
       ART_P_CAT_LEV_1                                                                          AS category_level_1,
       ART_BRAND_NAME                                                                           AS brand_name,
       ART_BRAND_TIER                                                                           AS brand_tier,
       ART_BRAND_OWNER                                                                          AS producer_name,
       IFNULL(art_content_volume, IFNULL(art_content_weight, IFNULL(art_content_pieces, NULL))) AS uom_amount,
       IFNULL(art_content_volume_uom, IFNULL(art_content_weight_uom, 'pieces'))                 AS uom,
       CASE
           WHEN uom = 'kilo' THEN uom_amount * 1000
           WHEN uom = 'liter' THEN uom_amount * 1000
           ELSE uom_amount
           END                                                                                  AS uom_amount_standardised,
       CASE WHEN uom = 'kilo' THEN 'gram' WHEN uom = 'liter' THEN 'ml' ELSE uom END             AS uom_standardised,
       ART_PACKAGING                                                                            AS packaging,
       CASE
           WHEN packaging = 'Box'
               OR packaging = 'Bag'
               OR packaging = 'Bottle'
               OR packaging = 'Tray'
               OR packaging = 'Pack'
               OR packaging = 'Jar'
               OR packaging = 'Can'
               OR packaging = 'Cup'
               OR packaging = 'Bucket'
               OR packaging = 'Blister'
               OR packaging = 'Tube'
               OR packaging = 'Pouch'
               OR packaging = 'Bar'
               THEN packaging
           END                                                                                  AS selected_packaging
FROM dim.DM_ARTICLE
WHERE ART_IN_STORE = 'yes'
;
