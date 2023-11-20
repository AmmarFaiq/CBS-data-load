

library(haven)
library(data.table)
library(memisc)



start_time = Sys.time()

GBAOVERLIJDENTAB_folder = "G:\\Bevolking\\GBAOVERLIJDENTAB\\2022\\"
GBAOVERLIJDENTAB_file = "GBAOVERLIJDEN2022TABV1.sav"

DO_common_path = "G:\\GezondheidWelzijn\\DO\\"
DO_primary_dirs = list.files(DO_common_path)[11:18] #2007 - 2012

DOORZTAB_common_path = "G:\\GezondheidWelzijn\\DOODOORZTAB\\"
DOORZTAB_primary_dirs = list.files(DOORZTAB_common_path)[1:10] #2013 - 2022

# 6. add information about deceased individuals from GBAOVERLIJDENTAB (from 1995 onward, contains date of death) for causes of death (ICD10 codes) Do (1995- 2012) and Doodoorztab (2012 and onward)
DODATUM = as.data.table(read_spss(paste(GBAOVERLIJDENTAB_folder,GBAOVERLIJDENTAB_file,sep=""),col_select = c(2,3)))

# create an empty dataframe
DO_data = data.table()

# loop for each year
for(dir in DO_primary_dirs){
  
  # define root folder with year included
  sub_folder = list.files(paste(DO_common_path,dir,sep=""))
  
  
  # do load the data if there is a file inside the folder
  if (any(grepl("+.sav", sub_folder))) {
    
    # get the filename inside the folder
    filename = sub_folder[grep("+.sav", sub_folder)][length(grep("+.sav", sub_folder))]
    
    # read the datafile
    if( dir == "2012"){
      temp_data = as.data.table(read_spss(file = paste(DO_common_path,dir,"\\",filename,sep=""), col_select = c(2,9,14) ))
      setnames(temp_data, colnames(temp_data), c("RINPERSOON","ICDCODE","YEAR"))
      temp_data$RINPERSOON = as.character(temp_data$RINPERSOON)
      temp_data$ICDCODE = as.character(temp_data$ICDCODE)
    }
    else{
      temp_data = as.data.table(read_spss(file = paste(DO_common_path,dir,"\\",filename,sep=""), col_select = c(2,7,12)))
      setnames(temp_data, colnames(temp_data), c("RINPERSOON","ICDCODE","YEAR"))
      temp_data$RINPERSOON = as.character(temp_data$RINPERSOON)
      temp_data$ICDCODE = as.character(temp_data$ICDCODE)
    }
    
    DO_data = rbindlist(list(DO_data,temp_data))
    rm(temp_data)
  }
}



# create an empty dataframe
DOORZTAB_data = data.table()

# loop for each year datafile
for(dir in DOORZTAB_primary_dirs){
  
  # define root folder with year included
  sub_folder = list.files(paste(DOORZTAB_common_path,dir,sep=""))
  
  
  # do load the data if there is a file inside the folder
  if (any(grepl("+.sav", sub_folder))) {
    
    # get the filename inside the folder
    filename = sub_folder[grep("+.sav", sub_folder)][length(grep("+.sav", sub_folder))]
    
    # read the datafile
    temp_data = as.data.table(read_spss(file = paste(DOORZTAB_common_path,dir,"\\",filename,sep=""), col_select =  c(2,3,7)))
    setnames(temp_data, colnames(temp_data), c("RINPERSOON","ICDCODE","YEAR"))
    temp_data$RINPERSOON = as.character(temp_data$RINPERSOON)
    temp_data$ICDCODE = as.character(temp_data$ICDCODE)
    
    DOORZTAB_data = rbindlist(list(DOORZTAB_data,temp_data))
    rm(temp_data)
  }
}


DOODOORZTAB = rbindlist(list(DO_data,DOORZTAB_data))
DOODOORZTAB = DOODOORZTAB[!is.na(RINPERSOON)]
DOODOORZTAB[, RINPERSOON := ifelse(nchar(RINPERSOON) < 9, paste0(strrep("0",times= 9 - nchar(RINPERSOON)),RINPERSOON),RINPERSOON)]


DOODOORZDATUM = merge(DOODOORZTAB, DODATUM, by = "RINPERSOON", all =T)

MIN_YEAR = 2009

DOODOORZDATUM = DOODOORZDATUM[ YEAR >= MIN_YEAR]

DOODOORZDATUM[,c("ICDCODE","GBADatumOverlijden") := lapply(.SD, function(x) na.locf(x, na.rm = F)), by = c("RINPERSOON"), .SDcols = c("ICDCODE","GBADatumOverlijden") ]



end_time = Sys.time()

end_time - start_time