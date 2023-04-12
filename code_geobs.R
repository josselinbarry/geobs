
# Library ----

library(tidyverse)
library(lubridate)
library(RcppRoll)
library(DT)
library(readxl)
library(dbplyr)
library(RPostgreSQL)
library(rsdmx)
library(sf)
library(stringi)

# Chargement données obstacles ----

## BDOE ----

bdoe_bzh <- data.table::fread(file = "data/export_de_base_20230330.csv")

bdoe_pdl <- data.table::fread(file = "data/export_de_base_20230330.csv")

## ROE ----

roe_lb <- readr::read_csv(file = "data/lb_temp20221219.csv",
                          locale(encoding = "UTF-8"),)

roe_sn <- readr::read_csv2(file = "data/sn_temp20221219.csv",
                           locale(encoding = "UTF-8"),)

# Fusionner les tables ---- 

roe_lb_sn <- dplyr::bind_rows(roe_lb, roe_sn)

bdoe_dr2 <- dplyr::bind_rows(bdoe_bzh, bdoe_pdl)

# Basculer le ROE en sf_geom

roe_geom <- roe_lb_sn %>% 
  st_as_sf(coords = c("x_l93", "y_l93"), remove = FALSE, crs = 2154) 
  
# Jointure et sélection des ROE et BDOE ----

jointure_bdroe <- roe_lb_sn %>% 
  dplyr::full_join(bdoe_bzh, 
                   by = c("identifiant_roe" = "cdobstecou")) %>% 
  dplyr::filter(email %in% c('camille.riviere@ofb.gouv.fr', 'didier.pujot@ofb.gouv.fr'))
