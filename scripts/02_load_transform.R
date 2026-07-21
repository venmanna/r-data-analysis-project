# Load and transform the vaccine dataset.
# Purpose: Load the vaccine time-series dataset and transform it to tidy form.

source("scripts/01_setup.R")

dataset_file <- file.path(raw_data_dir, "time_series_covid19_vaccine_doses_admin_US.csv")

if (!file.exists(dataset_file)) {
  stop("Dataset not found at: ", dataset_file)
}

state_lookup <- tibble(
  Province_State = c(state.name, "District of Columbia"),
  region = c(as.character(state.region), "South")
)

raw_vaccine <- readr::read_csv(dataset_file, show_col_types = FALSE)
date_columns <- names(raw_vaccine)[stringr::str_detect(names(raw_vaccine), "^\\d{4}-\\d{2}-\\d{2}$")]

vaccine_long <- raw_vaccine %>%
  filter(
    Country_Region == "US",
    Province_State %in% state_lookup$Province_State,
    !is.na(Population),
    Population > 0
  ) %>%
  select(Province_State, Population, all_of(date_columns)) %>%
  pivot_longer(
    cols = all_of(date_columns),
    names_to = "date",
    values_to = "cumulative_doses"
  ) %>%
  mutate(
    date = as.Date(date),
    cumulative_doses = as.numeric(cumulative_doses)
  ) %>%
  left_join(state_lookup, by = "Province_State") %>%
  arrange(Province_State, date) %>%
  group_by(Province_State) %>%
  mutate(
    daily_doses = cumulative_doses - lag(cumulative_doses, default = 0),
    daily_doses = if_else(daily_doses < 0, NA_real_, daily_doses),
    doses_per_100 = cumulative_doses / Population * 100,
    daily_doses_per_100k = daily_doses / Population * 100000,
    daily_doses_7day_avg = zoo::rollmean(daily_doses, k = 7, fill = NA, align = "right")
  ) %>%
  ungroup()

us_daily <- vaccine_long %>%
  group_by(date) %>%
  summarise(
    cumulative_doses = sum(cumulative_doses, na.rm = TRUE),
    daily_doses = sum(daily_doses, na.rm = TRUE),
    population = sum(Population, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    doses_per_100 = cumulative_doses / population * 100,
    daily_doses_7day_avg = zoo::rollmean(daily_doses, k = 7, fill = NA, align = "right")
  )

latest_state <- vaccine_long %>%
  group_by(Province_State) %>%
  filter(date == max(date, na.rm = TRUE)) %>%
  ungroup() %>%
  arrange(desc(doses_per_100))

readr::write_csv(vaccine_long, file.path(processed_data_dir, "vaccine_long.csv"))
readr::write_csv(us_daily, file.path(processed_data_dir, "us_daily.csv"))
readr::write_csv(latest_state, file.path(processed_data_dir, "latest_state.csv"))

message("Data loaded and transformed.")
