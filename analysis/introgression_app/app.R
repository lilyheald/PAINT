library(shiny)
library(leaflet)
library(wesanderson)
library(shinylive)
library(httpuv)

# ---- Fossil site data ----
genetic_sites <- data.frame(
  name = c("Denisova","Chagyrskaya","Vindija", "Mezmaiskaya",
           "El Sidron", "Spy", "Les Cottés"),
  samples = c(
    "Denisova 3 (Denisovan)\nDenisova 11 (F1 Hybrid)\nDenisova 5 (Neanderthal)",
    "Chagyrskaya 8 (Neanderthal)",
    "Vindija 33.19 (Neanderthal)",
    "Mezmaiskaya 1\nMezmaiskaya 2",
    "Sid1253 (Neanderthal)",
    "Spy 94-a (Neanderthal)",
    "Les Cottés Z4-1415 (Neanderthal)"
  ),
  lon  = c(84.7, 83.1, 16.8, 40, -5.3, 4.7, 2.5),
  lat  = c(51.4, 51.3, 46.3, 44.1, 43.4, 50.5, 46.2)
)

# ---- Adaptive introgression loci ----
adaptive_sites <- data.frame(
  name = c("EPAS1 (Tibet)", "OAS1 (Indonesia)", "BNC2 (Europe)"),
  lon = c(91, 113.9, 25),
  lat = c(30, -0.8, 54),
  description = c(
    "High-altitude adaptation (Denisovan introgression) (Zhang et al., 2021)",
    "Immune response (Neanderthal introgression) (Mendez et al., 2012)",
    "Skin pigmentation and freckling (Neanderthal introgression) (Sankararaman et al., 2014)"
  )
)

# --- Neanderthal introgression data (population level)
# from Sankararaman et al 2014
# add layer for gradient color

neanderthal_introgress <- data.frame(
  Region = c(rep("Europe", 4), rep("East Asia", 3), rep("America", 2),
             "Africa"),
  Population = c("FIN", "GBR", "IBS", "TSI",
                 "CHB", "CHS", "JPT",
                 "CLM", "PUR",
                 "LWK"),
  Location = c("Finland", "England", "Spain", "Italy",
               "Beijing", "Southern China", "Japan",
               "Colombia", "Puerto Rico",
               "Kenya"),
  lat = c(61.9, 52.9, 40.5, 41.9,
          39.5, 29.1, 36.2,
          4.6, 18.2,
          0), #N (+) S (-)
  lon = c(25.7, -2.3, -3.7, 12.6,
          116.2, 106.1, 138.3,
          -74.3, -66.6,
          37.9), #E (+) W (-)
  n = c(93, 89, 14, 98,
        97, 100, 89,
        60, 55,
        97),
  Perc_ancestry_autosome = c(1.20, 1.15, 1.07, 1.11,
                             1.40, 1.37, 1.38,
                             1.14, 1.05,
                             0.08)
)

#introgress_pal <- wes_palette("Zissou1", 100, type = "continuous")

# ---- Grid ----
lon <- seq(-180, 180, by = 1)
lat <- seq(-90, 90, by = 1)
grid <- expand.grid(lon = lon, lat = lat)

# ---- UI ----
ui <- fluidPage(
  titlePanel("Archaic Introgression Map"),

  sidebarLayout(
    sidebarPanel(
      checkboxInput("genetic_sites", "Show fossil sites with genetic data", TRUE),
      checkboxInput("adaptive", "Show adaptive loci", TRUE),
      checkboxInput("neanderthal_introgress", "Show percent autosomal introgression", TRUE)
    ),
    mainPanel(
      leafletOutput("map", height = 650)
    )
  )
)

# ---- Server ----
server <- function(input, output, session) {

  output$map <- renderLeaflet({
    leaflet() %>%
      addProviderTiles("CartoDB.Positron") %>%
      setView(lng = 40, lat = 30, zoom = 2)
  })

  observe({

    proxy <- leafletProxy("map")
    proxy %>% clearImages() %>% clearMarkers()

  # #3B9AB2 (blue), #78B7C5 (light blue), #EBCC2A (yellow), #E1AF00 (dark yellow), and #F21A00 (red)
    # ---- Fossil sites ----
    # displays site name and specimen names
    if (input$genetic_sites) {
      proxy %>%
        addCircleMarkers(
          data = genetic_sites,
          lng = ~lon, lat = ~lat,
          radius = 6,
          color = "black",
          fillColor = "#3B9AB2",
          fillOpacity = 0.9,
          popup = ~paste0("<b>", name, "</b><br/><pre>", samples, "</pre>")
        )
    }

    # ---- Adaptive loci ----
    # displays locus name and description of adaptation
    if (input$adaptive) {
      proxy %>%
        addCircleMarkers(
          data = adaptive_sites,
          lng = ~lon, lat = ~lat,
          radius = 7,
          color = "black",
          fillColor = "#F21A00",
          fillOpacity = 0.9,
          popup = ~paste0("<b>", name, "</b><br/>", description)
        )
    }
    # ---- Percent introgression ----
    # Displays the location (country or province) and percent autosomal introgression
    if (input$neanderthal_introgress) {
      proxy %>%
        addCircleMarkers(
          data = neanderthal_introgress,
          lng = ~lon, lat = ~lat,
          radius = 6,
          color = "black",
          fillColor = "#EBCC2A",
          fillOpacity = 0.9,
          popup = ~paste0("<b>", Location, "</b><br/><pre>", Perc_ancestry_autosome, "</pre>")
        )
    }
  })
}

# ---- Run app ----
shinyApp(ui, server)
