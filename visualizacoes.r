library(ggplot2)
library(outbreaks)
library(tidyverse)
library(ggraph)
library(tidygraph)
library(ggrepel)

#Quantidade de pessoas com erupção cutânea reportadas por dia
dates_prodrome <- measles_hagelloch_1861 %>%
  select(case_ID, date_of_prodrome) %>%
  group_by(date_of_prodrome) %>%
  summarise(frequency = n()) %>%
  rename(cases_prodrome = frequency) %>%
  rename(date = date_of_prodrome)

dates_rash <- measles_hagelloch_1861 %>%
  select(case_ID, date_of_rash) %>%
  group_by(date_of_rash) %>%
  summarise(frequency = n()) %>%
  rename(cases_rash = frequency) %>%
  rename(date = date_of_rash)

dates_all <- full_join(dates_prodrome, dates_rash, by = "date")
dates_all$cases_rash[is.na(dates_all$cases_rash)] <- 0
dates_all$cases_prodrome[is.na(dates_all$cases_prodrome)] <- 0

#Plot casos diários
ggplot(dates_all) +
  geom_area(aes(x = date, y= cases_rash, fill = 'Erupção Cutânea')) +
  geom_area(aes(x = date, y = cases_prodrome, fill = 'Sintomas iniciais', alpha= 0.5)) +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        plot.title = element_text(hjust = 0.5, size = 10)) +
  scale_x_date(date_labels = "%d/%m/%Y", date_breaks = "5 day") +
  labs(x = "Datas", y = "Número de casos diários", 
       title = "Surto epidêmico de sarampo na vila de Hagelloch, Alemanha, 1861") +
  scale_fill_manual("", values = c('#46e566', '#4befef', '#ff8457')) +
  guides(alpha = FALSE)

#Para quantas pessoas cada indivíduo infectado transmitiu a doença?
infector <- table(measles_hagelloch_1861$infector)
infector <- data.frame(Indivíduo = names(infector), 
                       Infectados_por_ele = as.vector(infector))
infector

ggplot(infector, aes(x = reorder(Indivíduo, Infectados_por_ele), y = Infectados_por_ele)) +
  geom_segment(aes(xend= Indivíduo, 
                   yend = 0), color="#ff8457") +
  geom_point(size= 4, color="#ff8457") +
  theme_bw() +
  theme(plot.title = element_text(hjust = 0.5, size = 15)) +
  coord_flip() +
  labs(y = "Quantidade de infectados pelo indíviduo", x = "Número de identificação", 
       title = "Quantidade de transmissões de sarampo \n por um indivíduo infectado")

#Localização
location <- measles_hagelloch_1861 %>%
  select(x_loc, y_loc, family_ID) 

location <- distinct(location)

ggplot(location, aes(x = x_loc, y = y_loc, 
                     label = family_ID)) +
  geom_point(colour = "#46e566") +
  geom_text_repel(aes(label = family_ID), size = 2.5) +
  theme_bw() +
  theme(plot.title = element_text(hjust = 0.5, size = 12)) +
  labs(title = "Localização espacial das casas das famílias afetadas pelo surto de sarampo \n em Hagelloch, Alemanha, 1861", x = "Coordenada x (em metros)", 
       y = "Coordenada y (em metros)")


#Transformando os dados para o formato aceitado pelo ggraph
nodes <- measles_hagelloch_1861 %>%
  select(case_ID, class)

infector_edge <- measles_hagelloch_1861 %>%
  select(infector, case_ID, class, x_loc, y_loc) %>%
  rename(from = infector) %>%
  rename(to = case_ID) %>%
  na.omit()

infector_tidy <- tbl_graph(edges = infector_edge, directed = TRUE, nodes = nodes)

#Casos gerados pelo 45
infector_edge45 <- measles_hagelloch_1861 %>%
  select(infector, case_ID, class, x_loc, y_loc) %>%
  rename(from = infector) %>%
  rename(to = case_ID) %>%
  filter(from == 45) %>%
  na.omit()

infector_tidy45 <- tbl_graph(edges = infector_edge45, directed = TRUE, nodes = nodes)

infector45 <- ggraph(infector_tidy45, layout = 'linear') +
  geom_edge_arc(aes(colour = class), width = 1.5) +
  theme_bw() +
  theme(axis.title.y = element_blank(),
        axis.text.y = element_blank(),
        axis.title.x = element_text(size = 20),
        panel.grid.minor = element_blank(),
        plot.title = element_text(hjust = 0.5, size = 30),
        axis.text.x = element_text(angle = 90, hjust = 1),
        legend.key.size = unit(1, "cm"),
        legend.box.background = element_rect(colour = "black"),
        legend.position = c(0.95,0.75)) +
  scale_x_continuous(breaks = infector_edge45$to) +
  labs(title = "Casos gerados pelo caso ID 45 durante o surto epidêmico de sarampo em Hagelloch, Alemanha, 1861", x = "\n Número de identificação dos casos.") +
  scale_edge_colour_manual("Classe", values = c('#46e566', '#4befef', '#ff8457'))


#Grafo direcionado 
infector2 <- ggraph(infector_tidy, layout = 'kk') +
  geom_edge_link(arrow = arrow(length = unit(1, 'mm')),
                 end_cap = circle(1.5, 'mm')) +
  geom_node_point(aes(colour = class), size = 3) +
  geom_node_text(aes(label = case_ID), repel = TRUE) + 
  theme_bw() +
  theme(axis.title.y = element_blank(),
        axis.text.y = element_blank(),
        axis.text.x = element_blank(),
        axis.title.x = element_blank(),
        plot.title = element_text(hjust = 0.5, size = 20),
        legend.box.background = element_rect(colour = "black"),
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        panel.background = element_blank(),
        legend.position = c(0.95,0.8)) +
  scale_colour_manual("Classe", values = c('#46e566', '#4befef', '#ff8457')) +
  labs(title = "Grafo direcionado com os infectados por cada indivíduo diagnosticado com sarampo")
