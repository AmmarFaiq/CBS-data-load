

library(haven)
library(data.table)
library(memisc)



start_time = Sys.time()

ZVWZORGKOSTENTAB_path = "G:\\GezondheidWelzijn\\ZVWZORGKOSTENTAB\\"
ZVWZORGKOSTENTAB_folder_list = list.files(ZVWZORGKOSTENTAB_path)[1:12]
ZVWZORGKOSTENTAB_select = c("RINPERSOON", "ZVWKHUISARTS", "ZVWKFARMACIE", "ZVWKMONDZORG", "ZVWKZIEKENHUIS", "ZVWKPARAMEDISCH", "ZVWKHULPMIDDEL", "ZVWKZIEKENVERVOER", "ZVWKGEBOORTEZORG", "ZVWKBUITENLAND", "ZVWKOVERIG", "ZVWKEERSTELIJNSPSYCHO", "ZVWKGGZ", "ZVWKGENBASGGZ", "ZVWKSPECGGZ", "ZVWKGERIATRISCH", "ZVWKWYKVERPLEGING", "NOPZVWKHUISARTSINSCHRIJF", "NOPZVWKHUISARTSCONSULT", "NOPZVWKHUISARTSOVERIG")

ZVWZORGKOSTENTAB_data = data.table()

for (dir in ZVWZORGKOSTENTAB_folder_list) {
  
  sub_folder_file = list.files(paste(ZVWZORGKOSTENTAB_path,dir,sep=""))
  
  if(any(grepl("+.sav", sub_folder_file))){
    filename = sub_folder_file[grepl("+.sav", sub_folder_file)][length(sub_folder_file[grepl("+.sav", sub_folder_file)])]
    filename = paste(ZVWZORGKOSTENTAB_path, dir, "\\", filename, sep="")
    temp_data = as.data.table(read_spss(file=paste(filename,sep=""), col_select = ZVWZORGKOSTENTAB_select))
    
    temp_data[, ZVWKOSTENTOTAAL := rowSums(.SD, na.rm = T), .SDcols = c("ZVWKHUISARTS", "ZVWKFARMACIE", "ZVWKMONDZORG", "ZVWKZIEKENHUIS", "ZVWKPARAMEDISCH", "ZVWKHULPMIDDEL", "ZVWKZIEKENVERVOER", "ZVWKGEBOORTEZORG", "ZVWKBUITENLAND", "ZVWKOVERIG", "ZVWKEERSTELIJNSPSYCHO", "ZVWKGGZ", "ZVWKGENBASGGZ", "ZVWKSPECGGZ", "ZVWKGERIATRISCH", "ZVWKWYKVERPLEGING")]
    
    temp_data[, ZVWKOSTENPSYCHO := rowSums(.SD, na.rm = T), .SDcols = c( "ZVWKGGZ", "ZVWKGENBASGGZ", "ZVWKSPECGGZ")]
  
    temp_data$YEAR = dir
     
    # temp_data = temp_data[A, on=c("RINPERSOON"), nomatch =NULL]
    
    ZVWZORGKOSTENTAB_data = rbindlist(list(ZVWZORGKOSTENTAB_data, temp_data))
    rm(temp_data)
    gc()
  }
}

end_time = Sys.time()

end_time - start_time