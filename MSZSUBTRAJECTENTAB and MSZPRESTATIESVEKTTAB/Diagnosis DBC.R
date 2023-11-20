

library(haven)
library(data.table)
library(memisc)


start_time = Sys.time()

DBC_common_path = "G:\\GezondheidWelzijn\\MSZSUBTRAJECTENTAB\\"
DBC_primary_dirs = list.files(DBC_common_path)[2:9]

DBC_prestatie_path = "G:\\GezondheidWelzijn\\MSZPRESTATIESVEKTTAB\\"
DBC_prestatie_folder_list = list.files(DBC_prestatie_path)[3:4]

Diagnosis_name = c("COPD","Hypertensie","Diabetes_I","Diabetes_II","Chronic_Hartfalen","OMA","Prostaatcarcinoom","Morbus_Parkinson","Heupfractuur", "BMI>45")
Specialisme_code = c("0322","0320","0313","0313","0320","0302","0306","0330","8418","0303")
Diagnose_code = c("1241","902","221","222","302","13","040","0501","303","342")


# create an empty dataframe
DBC_data = data.table()

# # select only selected population
# A = unique(ADD_DATA$RINPERSOON)

for(dir in DBC_primary_dirs){

  # define root folder with year included
    sub_folder = (paste(DBC_common_path,dir,sep=""))


    # do load the data if there is a file inside the folder
    if (any(grepl("+.sav", sub_folder))) {

      # get the filename inside the folder
      filename = sub_folder[grep("+.sav", sub_folder)][length(grep("+.sav", sub_folder))]

      temp_data = as.data.table(read_spss(file = filename, col_select = c(2,7,8,12)))

      # temp_data = temp_data[A, on=c("RINPERSOON"), nomatch =NULL]

      temp_data$YEAR = substr(dir,16,19)

      DBC_data = rbindlist(list(DBC_data,temp_data))
      rm(temp_data)
    }
}


DBC_prestatie_data = data.table()

for (dir in DBC_prestatie_folder_list) {

  sub_folder_file = list.files(paste(DBC_prestatie_path,dir,sep=""))

  if(any(grepl("+.sav", sub_folder_file))){
    filename = sub_folder_file[grepl("+.sav", sub_folder_file)][length(sub_folder_file[grepl("+.sav", sub_folder_file)])]
    filename = paste(DBC_prestatie_path, dir, "\\", filename, sep="")
    temp_data = as.data.table(read_spss(file=paste(filename,sep=""), col_select = c(2,12,13,18)))

    temp_data$YEAR = dir

    # temp_data = temp_data[A, on=c("RINPERSOON"), nomatch =NULL]

    DBC_prestatie_data = rbindlist(list(DBC_prestatie_data, temp_data))
    DBC_prestatie_data$VEKTMSZSpecialismeDiagnoseCombinatie = as.character(DBC_prestatie_data$VEKTMSZSpecialismeDiagnoseCombinatie)

    rm(temp_data)
    gc()
  }
}

temp_data = as.data.table(read_spss(file=paste("G:\\GezondheidWelzijn\\MSZPRESTATIESVEKTTAB2020\\MSZPrestatiesVEKT2020TABV3.sav",sep=""), col_select = c(2,12,13,18)))
temp_data$YEAR = "2020"
temp_data = temp_data[A, on=c("RINPERSOON"), nomatch =NULL]
DBC_prestatie_data = rbindlist(list(DBC_prestatie_data, temp_data))

rm(temp_data)

setnames(DBC_prestatie_data, c("VEKTMSZBegindatumZT","VEKTMSZEinddatumZT","VEKTMSZSpecialismeDiagnoseCombinatie"), c("MSZSTRBegindatumDBC","MSZSTREinddatumDBC", "MSZSTRSpecialismeDiagnoseCombinatie"))


DBC_data[,MSZSTRSpecialismeDiagnoseCombinatie := as.character(MSZSTRSpecialismeDiagnoseCombinatie)]
DBC_data = rbindlist(list(DBC_data, DBC_prestatie_data))

rm(DBC_prestatie_data)
gc()

DBC_data[YEAR != substr(MSZSTRBegindatumDBC,1,4), YEAR :=  substr(MSZSTRBegindatumDBC,1,4)]


DBC_prestatie_data = data.table()

DBC_data_first = data.table(RINPERSOON= character(), YEAR = character())
DBC_data_all = data.table(RINPERSOON= character()) 

for(i in 1:length(Diagnosis_name)){
  
  DBC_data_filtered = DBC_data[grepl(Specialisme_code[i], MSZSTRSpecialismeDiagnoseCombinatie) & grepl(Diagnose_code[i], MSZSTRSpecialismeDiagnoseCombinatie)][ order(MSZSTRBegindatumDBC)]
  
  DBC_data_filtered[, (Diagnosis_name[i]) := 1]
  DBC_data_filtered[, paste0("First",Diagnosis_name[i]) := 1]
  
  
  DBC_data_filtered = DBC_data_filtered[,c(1,2,5,7,6)]
  
  DBC_data_filtered[, datum := decimal_date(as.Date(MSZSTRBegindatumDBC, format = '%Y%m%d'))]
  
  DBC_data_filtered = DBC_data_filtered[ order(RINPERSOON, -datum)]
  
  DBC_data_filtered = DBC_data_filtered[ !duplicated(DBC_data_filtered, by = c("RINPERSOON", "YEAR"), fromLast = T)]
  
  DBC_data_filtered = DBC_data_filtered[ !duplicated(DBC_data_filtered, by = c("RINPERSOON"), fromLast = T)]
  
  DBC_data_filtered[, datum := NULL]
  
  DBC_data_filtered[, MSZSTRBegindatumDBC := NULL]
  
  DBC_data_first = merge(DBC_data_first,DBC_data_filtered[,c(1,2,3)],by = c("RINPERSOON","YEAR"), all=T, allow.cartesian = T)
  
  DBC_data_all = merge(DBC_data_all,DBC_data_filtered[,c(1,4)],by = c("RINPERSOON"), all=T, allow.cartesian = T)
  
}

rm(DBC_data)
rm(DBC_prestatie_data)
rm(DBC_data_filtered)

DBC_data_first = DBC_data_first[as.numeric(YEAR) > MIN_YEAR]

gc()

DBC_data_first[as.numeric(YEAR) > MAX_YEAR, YEAR:= as.character(MAX_YEAR)]


end_time = Sys.time()

end_time - start_time