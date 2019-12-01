library(dplyr)
library(lpSolve)
# install.packages("gmailr")
library(gmailr)
# Read https://github.com/r-lib/gmailr to configure gmail access.

ls()
rm(list=ls())

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

# Load Preferences
source('preferences.R')

students <- names(pref_order)

#gm_auth_configure(path = '/Users/ssteffen/Dropbox (MIT)/teaching/15.575/575 Fall 2019/ssteffen/credentials.json')
df <- data.frame(do.call(rbind, pref_order), stringsAsFactors = FALSE)
df <- bind_cols(df, first_names = first_names, emails = emails)


# Solve Preference Optimization. ------------------------------------------
# Fill matrix of ordinal preferences
prefs <- matrix(0, nrow = length(students), ncol = length(students))
for (i in 1:length(students)){
  row_name <- students[i]
  # print(row_name)
  if (length(pref_order[[row_name]]) == 0) next
  for (j in 1:length(pref_order[[students[i]]])){
    row <- i
    column <- which(pref_order[[row_name]][j] == students)
    prefs[row, column] <- 6 - j
  }
}

# Solve assignment problem.
lp.assign(prefs)
solution <- lp.assign(cost.mat = prefs, direction = 'max')$solution
max_indices <- apply(solution, 1, function(x) which.max(x))
has_to_review1 <- students[max_indices]

# Set previous matches to lowest preference and resolve assignment problem.
prefs1 <- prefs
for (i in 1:length(students)){
  row <- i
  column <- max_indices[i]
  prefs1[row, column] <- -1
}

# Solve assignment problem again.
lp.assign(prefs1)
solution1 <- lp.assign(cost.mat = prefs1, direction = 'max')$solution
max_indices1 <- apply(solution1, 1, function(x) which.max(x))
has_to_review2 <- students[max_indices1]

# Has to review
print(has_to_review1)
print(has_to_review2)

# Is reviewed by
is_reviewed_by1 <- students[match(students, has_to_review1)]
is_reviewed_by2 <- students[match(students, has_to_review2)]

# Prepare Automated Emails. -----------------------------------------------
df <- bind_cols(df, has_to_review1 = has_to_review1, has_to_review2 = has_to_review2, 
                is_reviewed_by1 = is_reviewed_by1, is_reviewed_by2 = is_reviewed_by2)

SUBJECT_ <- 'Paper Review Assignments for 15.575'
BODY_ <- list()

for (i in 1:length(students)){
  print(paste0('Creating email for: ', df$emails[i]))
  BODY_[[i]] <- paste0('Hi ', df$first_names[i], 
                       ",\nI hope you're having a wonderful Thanksgiving! ", 
                       "Here are the 2 people whose final papers you will review:\n", df$has_to_review1[i], ', and ', df$has_to_review2[i], '.\n',
                       "And here are the 2 people who will review your final paper:\n", df$is_reviewed_by1[i], ', and ', df$is_reviewed_by2[i], '.\n',
                       "\nAll the best,\n -Sebastian \n\n(I used R's {lpSolve} to match students according to their preferences and {gmailr} to send these emails. If there are any issues/questions, please let me know.)"
  )
  email_to_send <- 
    gm_mime() %>%
    gm_to(df$emails[i]) %>%
    gm_cc('erikb@mit.edu') %>% 
    gm_from("sebastian.steffen88@gmail.com") %>%
    gm_subject(SUBJECT_) %>%
    gm_text_body(BODY_[[i]])
}

df <- bind_cols(df, email_to_send = unlist(BODY_), )

# Draft and Send Emails. --------------------------------------------------
SEND_EMAIL_ <- FALSE
DRAFT_EMAIL_ <- FALSE

if ((!SEND_EMAIL_) & (!DRAFT_EMAIL_)) {
  for (i in 1:length(students)){
    # Wait between each email to stay within gmail's rate limits.
    Sys.sleep(0.5)
    if (DRAFT_EMAIL_){
      # Verify emails look correct and save a draft.
      gm_create_draft(df$email_to_send[i])
    }
    if (SEND_EMAIL_){
      # If all is good with your draft, then you can send it
      gm_send_message(df$email_to_send[i])
    }
  }
}
