

library(haven)
library(data.table)
library(memisc)



start_time = Sys.time()



GBAPERSOON = as.data.table(read_spss(paste(GBAPERSOONTAB_folder,GBAPERSOONTAB_file,sep=""),col_select = c(2,4,8,9,10:12)))
GBAPERSOON = as.data.table(unite(GBAPERSOON, "GBAGEBOORTEDATUM", c("GBAGEBOORTEJAAR","GBAGEBOORTEMAAND","GBAGEBOORTEDAG"),sep = ""))

# GBAPERSOON = GBAPERSOON[A, on=("RINPERSOON"), nomatch =NULL]


# ADD_DATA = merge(ADD_DATA,GBAPERSOON,by = "RINPERSOON")
# rm(GBAPERSOON)
gc()

end_time = Sys.time()

end_time - start_time