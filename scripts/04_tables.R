# Generate supporting analysis tables.
# Purpose: Generate three supporting tables for the report.

source("scripts/03_visualizations.R")

table_1_latest_state_summary <- latest_state %>%
  transmute(state = Province_State, region, population = Population, latest_date = date, cumulative_doses, doses_per_100 = round(doses_per_100, 1)) %>%
  arrange(desc(doses_per_100))

table_2_milestone_summary <- milestones %>%
  arrange(first_100_per_100) %>%
  transmute(state = Province_State, region, first_50_per_100, first_100_per_100, first_150_per_100)

table_3_region_quarter_summary <- quarterly_region %>%
  mutate(doses_per_100 = round(doses_per_100, 1)) %>%
  arrange(region, quarter)

readr::write_csv(table_1_latest_state_summary, file.path(table_dir, "table_1_latest_state_summary.csv"))
readr::write_csv(table_2_milestone_summary, file.path(table_dir, "table_2_milestone_summary.csv"))
readr::write_csv(table_3_region_quarter_summary, file.path(table_dir, "table_3_region_quarter_summary.csv"))

message("Three supporting tables saved to output/tables/.")
