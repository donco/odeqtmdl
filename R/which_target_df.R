#' Which TMDL target ID applies
#'
#' Takes a dataframe with sample reachcode, parameter, and date and returns the TMDL target info
#' @param df Data frame in which to add target information
#' @return Data frame with tmdl target columns
#' @export
#' @examples
#' which_target(df)

which_target_df <- function(df, all_obs = TRUE){

  df <- merge(df, tmdl_db[, c("ReachCode", "pollutant_name_AWQMS", "geo_id", "target_value", "target_units", "target_stat_base", "season_start", "season_end")],
              by.x = c("Reachcode", "Char_Name"), by.y = c("ReachCode", "pollutant_name_AWQMS"), all.x = all_obs, all.y = FALSE)

  df <- df %>% dplyr::mutate(
    # Append start and end dates with year
    start_datetime = ifelse(!is.na(season_start), paste0(season_start, "-", lubridate::year(sample_datetime)), NA ) ,
    end_datetime = ifelse(!is.na(season_end), paste0(season_end, "-", lubridate::year(sample_datetime)), NA ),
    # Make dates POSIXct format
    start_datetime = as.POSIXct(start_datetime, format = "%d-%b-%Y"),
    end_datetime = as.POSIXct(end_datetime, format = "%d-%b-%Y"),
    # If dates span a calendar year, account for year change in end date
    end_datetime = if_else(end_datetime < start_datetime & date >= end_datetime, end_datetime + lubridate::years(1), # add a year if inperiod carrying to next year
                           end_datetime), # otherwise, keep End_spawn as current year
    start_datetime = if_else(end_datetime < start_datetime & date <= end_datetime, start_datetime - lubridate::years(1), # subtract a year if in period carrying from previous year
                             start_datetime),
    tmdl_season = if_else(sample_datetime >= start_datetime & sample_datetime <= end_datetime, TRUE, FALSE),
    criteria = if_else(tmdl_season, geo_id, NA_character_)
    ) %>% dplyr::select(-season_start, -season_end, -geo_id)

  return(df)

}