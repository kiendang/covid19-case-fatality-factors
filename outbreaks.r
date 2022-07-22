library(dplyr)
library(tidyr)
library(lubridate)
library(jsonlite)


data_dir <- file.path(".", "data")


msa_dict <- fromJSON(file.path(data_dir, "msa_dict.json"))


msa_dict_df <- data.frame(
  id = names(msa_dict),
  msa = unlist(msa_dict)
) |> mutate(id = as.integer(id))


msa_cumulative_cases <- data.table::fread(
  file.path(data_dir, "msa_cumulative_cases.csv"),
  header = TRUE,
  data.table = FALSE
) |> rename(id = 1)


msa_cumulative_deaths <- data.table::fread(
  file.path(data_dir, "msa_cumulative_deaths.csv"),
  header = TRUE,
  data.table = FALSE
) |> rename(id = 1)


msa_cumulative_cases <-
  msa_dict_df |> right_join(msa_cumulative_cases, by = "id")


msa_cumulative_deaths <-
  msa_dict_df |> right_join(msa_cumulative_deaths, by = "id")


msa_cumulative_cases_long <- pivot_longer(
  msa_cumulative_cases, !c(1, 2), names_to = "date", values_to = "cases"
) |>
  mutate(date = ymd(date))


msa_cumulative_deaths_long <- pivot_longer(
  msa_cumulative_deaths, !c(1, 2), names_to = "date", values_to = "deaths"
) |>
  mutate(date = ymd(date))


outbreak_threshold <- 10000


outbreaks <- msa_cumulative_cases_long |>
  filter(cases >= outbreak_threshold)


remove_last_chars <- function(n = 4) {
  function(x) { sapply(x, function(x) substr(x, 1, nchar(x) - n), USE.NAMES = FALSE) }
}


msa_demographics_files <-
  list.files(file.path(data_dir, "Region_Demographics"), ".csv")


msa_with_file <- msa_demographics_files |> remove_last_chars()()


msa_population <- msa_with_file |>
  map(function(f) {
    data.table::fread(
      file.path(data_dir, "Region_Demographics", paste0(f, ".csv")),
      header = TRUE,
      data.table = FALSE
    ) |>
      select(-1, -census_tract, -median_household_income) |>
      summarise_all(sum) |>
      mutate(msa = f)
  }) |>
  data.table::rbindlist() |>
  as.data.frame() |>
  relocate(msa, .before = everything())


msa_cumulative_cases_long_lag <- msa_cumulative_cases_long |>
  group_by(id) |>
  arrange(date) |>
  mutate(prev = lag(cases, 1)) |>
  mutate(prev = ifelse(is.na(prev), cases, prev)) |>
  ungroup()


msa_new_cases <- msa_cumulative_cases_long_lag |>
  mutate(new = cases - prev)


outbreaks_cases_periods <- msa_new_cases |>
  filter(new >= outbreak_threshold) |>
  select(id, date) |>
  left_join(msa_cumulative_cases_long |> select(id, date_ = date), by = "id") |>
  group_by(id, date) |>
  mutate(
    date_1_prior = date - ddays(1),
    date_30_prior = date - ddays(30 + 1),
    date_60_after = date + ddays(60 - 1),
    date_90_after = date + ddays(90 - 1)
  ) |>
  summarise(
    date_1_prior =
      if (any(date_ == date_1_prior)) first(date_1_prior) else max(pmin(date, date_)),
    date_30_prior =
      if (any(date_ == date_30_prior)) first(date_30_prior) else max(pmin(date, date_)),
    date_60_after =
      if (any(date_ == date_60_after)) first(date_60_after) else min(pmax(date, date_)),
    date_90_after =
      if (any(date_ == date_90_after)) first(date_90_after) else min(pmax(date, date_))
  ) |>
  ungroup()


outbreaks_0 <- outbreaks_cases_periods |>
  left_join(
    msa_cumulative_deaths_long |> select(id, date_1_prior = date, begin_deaths = deaths),
    by = c("id", "date_1_prior")
  ) |>
  left_join(
    msa_cumulative_deaths_long |> select(id, date_90_after = date, end_deaths = deaths),
    by = c("id", "date_90_after")
  ) |>
  left_join(
    msa_cumulative_cases_long |> select(id, date_30_prior = date, begin_cases = cases),
    by = c("id", "date_30_prior")
  ) |>
  left_join(
    msa_cumulative_cases_long |> select(id, date_60_after = date, end_cases = cases),
    by = c("id", "date_60_after")
  ) |>
  mutate(
    total_cases = end_cases - begin_cases,
    total_deaths = end_deaths - begin_deaths
  ) |>
  select(id, date, total_cases, total_deaths)


outbreaks_1 <- msa_new_cases |>
  select(id, msa, date, new_cases = new) |>
  right_join(outbreaks_0, by = c("id", "date"))


outbreaks <- outbreaks_1 |>
  left_join(msa_population |> select(msa, population), by = "msa") |>
  mutate(death_percentage = round(total_deaths / total_cases * 100, 2)) |>
  relocate(population, .after = last_col())


data.table::fwrite(outbreaks, file.path(data_dir, "outbreaks_10000.csv"))
