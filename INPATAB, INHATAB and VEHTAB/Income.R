

library(haven)
library(data.table)
library(memisc)



start_time = Sys.time()

INPATAB_common_path = "G:\\InkomenBestedingen\\INPATAB\\"
INPATAB_primary_dirs = list.files(INPATAB_common_path)[2:12] # 2011 -2021

INPATAB_select = c("RINPERSOON", "RINPERSOONHKW", "INPBELI", "INPPERSINK", "INPSECJ","INPT3170RBW","INPT3180RST", "INPT3190RBS")


VEHTAB_common_path = "G:\\InkomenBestedingen\\VEHTAB\\"
VEHTAB_primary_dirs = list.files(VEHTAB_common_path)

VEHTAB_primary_dirs = VEHTAB_primary_dirs[grep("^VEH+", VEHTAB_primary_dirs) ]
VEHTAB_primary_dirs = VEHTAB_primary_dirs[grep("+.sav", VEHTAB_primary_dirs)]

VEHTAB_primary_dirs= VEHTAB_primary_dirs[6:15]

INHATAB_common_path = "G:\\InkomenBestedingen\\INHATAB\\"
INHATAB_primary_dirs = list.files(INHATAB_common_path)[2:12] # 2011 -2021

INHATAB_select = c("RINPERSOONHKW", "INHAHL", "INHGESTINKH", "INHPOPIIV", "INHSAMAOW", "INHSAMHH", "INHUAFTYP", "INHARMLAG")

# # uncomments if you want to select population
# A = unique(ADD_DATA$RINPERSOON)

## create an empty dataframe
INPATAB_data = data.table()

for(dir in INPATAB_primary_dirs){

  # define root folder with year included
    sub_folder = (paste(INPATAB_common_path,dir,sep=""))


    # do load the data if there is a file inside the folder
    if (any(grepl("+.sav", sub_folder))) {

      # get the filename inside the folder
      filename = sub_folder[grep("+.sav", sub_folder)][length(grep("+.sav", sub_folder))]

      temp_data = as.data.table(read_sav(file = filename, col_select = INPATAB_select))

    #   temp_data = temp_data[A, on=c("RINPERSOON"), nomatch =NULL]
      temp_data$YEAR = substr(dir,5,8)

      INPATAB_data = rbindlist(list(INPATAB_data,temp_data))
      rm(temp_data)
    }
}

# create an empty dataframe
INHATAB_data = data.table()

for(dir in INHATAB_primary_dirs){
    
  # define root folder with year included
    sub_folder = (paste(INHATAB_common_path,dir,sep=""))
    
    
    # do load the data if there is a file inside the folder
    if (any(grepl("+.sav", sub_folder))) {
      
      # get the filename inside the folder
      filename = sub_folder[grep("+.sav", sub_folder)][length(grep("+.sav", sub_folder))]

      temp_data = as.data.table(read_sav(file = filename, col_select = INHATAB_select))

    #   temp_data = temp_data[A, on=c("RINPERSOONHKW"), nomatch =NULL]
      
      temp_data$YEAR = substr(dir,5,8)

      INHATAB_data = rbindlist(list(INHATAB_data,temp_data))
      rm(temp_data)
    }
}

# create an empty dataframe
VEHTAB_data = data.table()

for(dir in VEHTAB_primary_dirs){

  # define root folder with year included
    sub_folder = (paste(VEHTAB_common_path,dir,sep=""))

      # get the filename inside the folder
    filename = sub_folder[grep("+.sav", sub_folder)][length(grep("+.sav", sub_folder))]
    temp_data = as.data.table(read_spss(file = filename, col_select =c(2,3,4)))

    # temp_data = temp_data[A, on=c("RINPERSOONHKW"), nomatch =NULL]

    temp_data$YEAR = substr(dir,4,7)

    VEHTAB_data = rbindlist(list(VEHTAB_data,temp_data))
    rm(temp_data)

}

gc()

end_time = Sys.time()

end_time - start_time