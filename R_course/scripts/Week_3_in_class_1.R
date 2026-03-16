install.packages("babynames")
library(tidyverse)

top10_names <- babynames %>%
  group_by(name) %>%
  summarise(total = sum(n)) %>%
  arrange(desc(total)) %>%
  slice_head(n = 10)

ggplot(top10_names, aes(x = name, y = total)) +
  geom_bar(stat = "identity")


names_i_want <- c("Mary", "John", "Robert", "James", "William")
class(names_i_want)
class(marie_1920)


marie_1920 <- babynames |> 
  filter(name == "Marie", year == 1920)

selected_names <- babynames |> 
 filter(name %in% names_i_want, year == 1920 )        
         
head(marie_1920)

  marie_sorted <- babynames |>
    filter(name == "Marie", sex == "F") |>
    arrange(desc(prop))
  
  head(marie_sorted)
  
  top_3_boys_2000 <- babynames |>
    filter(year == 2015, sex == "F") |>
    slice_max(order_by = n, n = 10)
  
  top_3_boys_2000 <- babynames |>
    filter(year == 1915, sex == "F") |>
    slice_max(order_by = n, n = 10)
  top_3_boys_2000