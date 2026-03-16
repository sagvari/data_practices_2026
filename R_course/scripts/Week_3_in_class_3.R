library(tidyverse)
library(babynames)
library(scales)

# 1. Filter and Prepare the main dataset
plot_data <- babynames %>%
  filter(
    (name == "Mary" & sex == "F") | 
      (name == "James" & sex == "M")
  )

# 2. Calculate Peak Years for each name individually
# This creates a 'lookup table' for our vertical lines and annotations
peaks <- plot_data %>%
  group_by(name) %>%
  slice_max(prop, n = 1) %>%
  ungroup()

print(peaks) # Review the peak years before plotting

ggplot(plot_data, aes(x = year, y = prop, color = name)) +
  # Main time-series lines
  geom_line(linewidth = 1) +
  
  # Vertical indicators for peak years
  geom_vline(data = peaks, 
             aes(xintercept = year, color = name), 
             linetype = "dashed", alpha = 0.7) +
  
  # Annotate the peak years
  # nudge_x is used to prevent the text from overlapping the vertical line
  geom_text(data = peaks, 
            aes(x = year, y = prop, label = paste("Peak:", year)),
            vjust = -1, hjust = -0.1, size = 3.5, show.legend = FALSE) +
  
  # Styling and Scales
  scale_y_continuous(labels = scales::label_percent()) +
  scale_color_brewer(palette = "Set1") + # High contrast for academic printing
  theme_minimal() +
  labs(
    title = "Historical Popularity of Traditional Names in the United States",
    subtitle = "Proportional frequency of 'Mary' (F) and 'James' (M) from 1880 to 2017",
    x = "Year of Birth",
    y = "Proportion of Total Births",
    color = "Name",
    caption = "Source: Social Security Administration (babynames R package)"
  ) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold")
  )




# make a chart of the top 10 most popular names for each
top_names <- babynames %>%
  group_by(name) %>%
  summarise(total_prop = sum(prop)) %>%
  arrange(desc(total_prop)) %>%
  slice_head(n = 20)