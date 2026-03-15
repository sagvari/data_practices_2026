library(plotly)
library(babynames)
library(dplyr)

# Select 4 example names (change as needed)
selected_names <- c("Mary", "John", "Jennifer", "Michael")

# Filter data
data <- babynames %>%
  filter(name %in% selected_names)

# Create plotly time series
plot_ly(data, x = ~year, y = ~prop, color = ~name, type = "scatter", mode = "lines") %>%
  layout(
    title = "Baby Name Popularity Over Time",
    xaxis = list(title = "Year"),
    yaxis = list(title = "Proportion of Births"),
    hovermode = "x unified",
    plot_bgcolor = "#f8f9fa",
    font = list(size = 12)
  ) %>%
  add_lines(line = list(width = 2)) %>%
  config(responsive = TRUE)

