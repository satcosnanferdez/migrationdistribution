library(sf)
library(dplyr)
library(countrycode)
library(geosphere)
library(haven)
map <- read_sf("/media/jcosta/b2ef1e75-4584-41d2-8b84-7a7ab9514eda/EconLetters/Data/Orig/ArcGIS/World_Cities.geojson") %>%
    group_by(FIPS_CNTRY) %>%
    filter(POP == max(POP)) %>%
    select(FIPS_CNTRY, CNTRY_NAME, CITY_NAME, POP) %>%
    arrange(CNTRY_NAME, CITY_NAME) %>%
    ungroup() %>% 
    mutate(iso2c = countrycode(FIPS_CNTRY, "fips", "iso2c"))

GB <- map %>% filter(iso2c == "GB")
map <- map %>% filter(iso2c != "GB")

D <- tibble(iso2c = map$iso2c, 
       distance = distVincentyEllipsoid(st_coordinates(GB), st_coordinates(map))) %>%
    group_by(iso2c) %>%
    summarise(distance = mean(distance))

write_dta(D, "Distances.dta")

