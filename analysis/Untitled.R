# Input/Output
input_file  <- "/Users/lilyheald/Desktop/download-links.txt"
output_file <- "/Users/lilyheald/Desktop/wget_commands.txt"

# Read links
links <- scan(input_file, what = character(), sep = "\n", quiet = TRUE)

# Trim whitespace
links <- trimws(links)

# Remove blank lines
links <- links[nchar(links) > 0]

# Ensure https prefix
links <- ifelse(grepl("^https:", links), links, paste0("https:", links))

# Extract filename from URL (everything after the last / before any ?)
filenames <- sub("^.*/([^/?]+).*", "\\1", links)

# Construct wget commands with clean filenames
wget_lines <- sprintf('wget -c -O "%s" "%s"', filenames, links)

# Write to file
writeLines(wget_lines, output_file)

# Summary
cat("Total links read:", length(links), "\n")
cat("Total wget commands written:", length(wget_lines), "\n")
cat("First 5 filenames:\n")
print(head(filenames, 5))

