WITH latest_scrape_dates AS (
    SELECT STORE_ID,
           MAX(DATE(LAST_UPDATED)) AS latest_scrape_date
    FROM dim.FT_SUPERSCANNER_ARTICLE_PRICE AS cp_art
    GROUP BY STORE_ID
)
SELECT cp_art.COMP_ART_SALESFORCE_ID   AS id,
       REGEXP_REPLACE(cp_price.LOAD_QUERY_SUPERMARKET, '_de|_fr| online', '') as competitor,
       LOWER(cp_art.COMP_ART_SUPERMARKET),
       cp_art.COMPETITOR_ARTICLE_ID    AS retailer_id,
       cp_art.COMP_ART_NAME            AS name,
       cp_price.price                  AS latest_selling_price,
       latest_scrape_dates.latest_scrape_date,
       cp_price.main_category          AS main_category,
       cp_price.sub_category           AS sub_category,
       cp_price.UNIT_VALUE             AS uom_amount_standardised,
       cp_price.UNIT_MEASUREMENT       AS cp_competitor_content_unit__c,
       CASE
           WHEN cp_competitor_content_unit__c = 'g' THEN 'gram'
           ELSE cp_competitor_content_unit__c
           END                         AS uom_standardised,
       LOWER(NULLIF(cp_art.COMP_ART_BRAND,false)) AS brand_name,
       cp_art.COMP_ART_BRAND_TIER AS brand_tier,
       cp_art.COMP_ART_PACKAGING       AS packaging,
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
           END                         AS selected_packaging
FROM dim.DM_COMPETITOR_ARTICLE AS cp_art
         INNER JOIN dim.FT_SUPERSCANNER_ARTICLE_PRICE AS cp_price
                    ON cp_art.COMPETITOR_ARTICLE_ID = cp_price.STORE_ID
         INNER JOIN dim.DM_DATE
                    ON cp_price.KEY_DATE = DM_DATE.KEY_DATE
         INNER JOIN latest_scrape_dates
                    ON cp_art.COMPETITOR_ARTICLE_ID = latest_scrape_dates.STORE_ID
WHERE DM_DATE.date = CURRENT_DATE()
  AND cp_price.price_line_type = 'default'
  AND (latest_scrape_date > DATEADD(DAY, -7, GETDATE()))
  AND id IS NOT NULL
;
