# Generate six R visualizations for the analysis.

source("scripts/02_load_transform.R")

caption_text <- "Source: Johns Hopkins University CSSE COVID-19 vaccine time-series dataset."

plot_1 <- ggplot(us_daily, aes(x = date, y = cumulative_doses)) +
  geom_line(color = "#1f6f8b", linewidth = 1) +
  scale_y_continuous(labels = label_number(scale_cut = cut_short_scale())) +
  labs(title = "U.S. cumulative vaccine doses rose sharply before plateauing", subtitle = "Cumulative administered doses, December 2020 to March 2023", x = NULL, y = "Cumulative doses", caption = caption_text)
ggsave(file.path(figure_dir, "01_us_cumulative_doses.png"), plot_1, width = 9, height = 5, dpi = 300)

plot_2 <- ggplot(us_daily, aes(x = date)) +
  geom_col(aes(y = daily_doses), fill = "gray80", width = 1) +
  geom_line(aes(y = daily_doses_7day_avg), color = "#b43f3f", linewidth = 1) +
  scale_y_continuous(labels = label_number(scale_cut = cut_short_scale())) +
  labs(title = "Daily vaccination throughput peaked early in the rollout", subtitle = "Bars show daily doses; line shows 7-day moving average", x = NULL, y = "Daily doses", caption = caption_text)
ggsave(file.path(figure_dir, "02_us_daily_doses_7day_average.png"), plot_2, width = 9, height = 5, dpi = 300)

plot_3 <- latest_state %>%
  slice_max(doses_per_100, n = 15) %>%
  ggplot(aes(x = reorder(Province_State, doses_per_100), y = doses_per_100)) +
  geom_col(fill = "#1f6f8b") +
  coord_flip() +
  labs(title = "Highest state vaccine dose rates by the final reporting date", subtitle = "Cumulative doses administered per 100 residents", x = NULL, y = "Doses per 100 residents", caption = caption_text)
ggsave(file.path(figure_dir, "03_top_states_doses_per_100.png"), plot_3, width = 9, height = 5, dpi = 300)

plot_4 <- latest_state %>%
  slice_min(doses_per_100, n = 15) %>%
  ggplot(aes(x = reorder(Province_State, doses_per_100), y = doses_per_100)) +
  geom_col(fill = "#b43f3f") +
  coord_flip() +
  labs(title = "Lowest state vaccine dose rates by the final reporting date", subtitle = "Cumulative doses administered per 100 residents", x = NULL, y = "Doses per 100 residents", caption = caption_text)
ggsave(file.path(figure_dir, "04_bottom_states_doses_per_100.png"), plot_4, width = 9, height = 5, dpi = 300)

milestones <- vaccine_long %>%
  group_by(Province_State, region) %>%
  summarise(
    first_50_per_100 = suppressWarnings(min(date[doses_per_100 >= 50], na.rm = TRUE)),
    first_100_per_100 = suppressWarnings(min(date[doses_per_100 >= 100], na.rm = TRUE)),
    first_150_per_100 = suppressWarnings(min(date[doses_per_100 >= 150], na.rm = TRUE)),
    .groups = "drop"
  ) %>%
  mutate(across(starts_with("first_"), ~ if_else(is.infinite(.x), as.Date(NA), as.Date(.x))))

plot_5 <- milestones %>%
  filter(!is.na(first_100_per_100)) %>%
  arrange(first_100_per_100) %>%
  ggplot(aes(x = first_100_per_100, y = reorder(Province_State, first_100_per_100), color = region)) +
  geom_point(size = 2.5) +
  labs(title = "States reached 100 doses per 100 residents at different speeds", subtitle = "Earlier milestone dates suggest faster early distribution and uptake", x = "Date reached 100 doses per 100 residents", y = NULL, color = "Region", caption = caption_text)
ggsave(file.path(figure_dir, "05_state_milestone_100_per_100.png"), plot_5, width = 9, height = 8, dpi = 300)

quarterly_region <- vaccine_long %>%
  mutate(quarter = paste0(year(date), " Q", quarter(date))) %>%
  group_by(region, quarter) %>%
  summarise(
    total_daily_doses = sum(daily_doses, na.rm = TRUE),
    population = sum(Population, na.rm = TRUE) / n_distinct(date),
    doses_per_100 = total_daily_doses / population * 100,
    .groups = "drop"
  )

plot_6 <- ggplot(quarterly_region, aes(x = quarter, y = doses_per_100, fill = region)) +
  geom_col(position = "dodge") +
  labs(title = "Regional vaccine activity shifted over the rollout", subtitle = "Quarterly administered doses per 100 residents by Census region", x = NULL, y = "Quarterly doses per 100 residents", fill = "Region", caption = caption_text) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggsave(file.path(figure_dir, "06_quarterly_region_doses_per_100.png"), plot_6, width = 10, height = 5.5, dpi = 300)

message("Six visualizations saved to output/figures/.")
