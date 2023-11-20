

library(haven)
library(data.table)
library(memisc)



start_time = Sys.time()


VSLGWBTAB_folder = "G:\\BouwenWonen\\VSLGWBTAB\\"
VSLGWBTAB_file = "VSLGWB2022TAB03V2.sav"

GBAADRESOBJECTBUS_folder = "G:\\Bevolking\\GBAADRESOBJECTBUS\\"
GBAADRESOBJECTBUS_file = "GBAADRESOBJECT2022BUSV1.sav"


GBAPERSOONTAB_folder = "G:\\Bevolking\\GBAPERSOONTAB\\2022\\"
GBAPERSOONTAB_file = "GBAPERSOON2022TABV1.sav"

# 's-Gravenhage	0518
# Rijswijk	0603
# Wassenaar	0629
# Leidschendam-Voorburg	1916

# Delft	0503
# Zoetermeer	0637
# Westland	1783
# Midden-Delfland	1842

# Pijnacker-Nootdorp	1926
# rm(ADD_DATA)
gemcode = c("0518","0603", "0629", "1916")

gc()

MIN_YEAR = 2008
MAX_YEAR = 2022

GWBTAB = as.data.table(read_spss(paste(VSLGWBTAB_folder,VSLGWBTAB_file,sep=""),col_select = c(2,27:74))) #2007 - 2022

## convert wide format to long format of the data, with column name pattern that contains wc, bc, and gem
GWBTAB = melt(GWBTAB, measure = patterns("wc","bc","gem"), variable.name = "YEAR", value.name = c("wc","bc","gem"))

## year is just a dummy column name that used to the melt function.
GWBTAB[,YEAR:=NULL]

#GWBTAB = GWBTAB[!duplicated(GWBTAB,by=colnames(GWBTAB),fromLast = T)]
ADDDATUM= as.data.table(read_spss(paste(GBAADRESOBJECTBUS_folder,GBAADRESOBJECTBUS_file,sep=""),col_select = c(2,3,4,6)))

# Get list of unique rinobjectnumber based on selected gementee code
A = unique(GWBTAB[gemcode, on=c("gem"), nomatch =NULL]$RINOBJECTNUMMER)
# Get list of unique Rinpersoon based on selected rinobjectnummer
B = unique(ADDDATUM[A, on=c("RINOBJECTNUMMER"), nomatch =NULL]$RINPERSOON)

ADDDATUM = ADDDATUM[B, on=c("RINPERSOON"), nomatch =NULL]

C = unique(ADDDATUM$RINOBJECTNUMMER)

GWBTAB = GWBTAB[C, on=c("RINOBJECTNUMMER"), nomatch =NULL]
gc()

#merge 

ADD_DATA = merge(GWBTAB,ADDDATUM,by = "RINOBJECTNUMMER", allow.cartesian = T)
# length(unique(ADD_DATA[gem == "0518"][YEAR=="2011"]$RINPERSOON))

#remove duplicates
ADD_DATA = ADD_DATA[!duplicated(ADD_DATA,by=c("RINPERSOON","RINOBJECTNUMMER","wc", "bc", "gem", "GBADATUMAANVANGADRESHOUDING", "GBADATUMEINDEADRESHOUDING"),fromLast = F)]


A = unique(ADD_DATA$RINPERSOON)

rm(ADDDATUM)
rm(GWBTAB)
gc()

ADD_DATA = ADD_DATA[gemcode, on=c("gem"), nomatch =NULL]

A = unique(ADD_DATA$RINPERSOON)

gc()

# change the moving end date not later than minimum year
ADD_DATA = ADD_DATA[as.numeric(substr(GBADATUMEINDEADRESHOUDING,1,4)) >= MIN_YEAR ]

# change the typo/ date that is higher than allowed maximum year
ADD_DATA[as.numeric(substr(ADD_DATA$GBADATUMEINDEADRESHOUDING,1,4)) > MAX_YEAR , GBADATUMEINDEADRESHOUDING := paste0(MAX_YEAR,"1231")]

# change the moving in date 
ADD_DATA[as.numeric(substr(ADD_DATA$GBADATUMAANVANGADRESHOUDING,1,4)) <= MIN_YEAR , GBADATUMAANVANGADRESHOUDING := paste0(MIN_YEAR,"0101")]

# we found out that there are some people who are registered into two address in the same period of time. We will choose only one of them
ADD_DATA = ADD_DATA[!duplicated(ADD_DATA,by=c("RINPERSOON", "GBADATUMAANVANGADRESHOUDING", "GBADATUMEINDEADRESHOUDING"),fromLast = F)]

ADD_DATA[, DIFF := as.Date(GBADATUMEINDEADRESHOUDING, format= "%Y%m%d") - as.Date(GBADATUMAANVANGADRESHOUDING, format= "%Y%m%d")]


ADD_DATA= ADD_DATA[order(RINPERSOON,GBADATUMAANVANGADRESHOUDING, DIFF)]

ADD_DATA = ADD_DATA[!duplicated(ADD_DATA,by=c("RINPERSOON", "GBADATUMAANVANGADRESHOUDING"),fromLast = T)]

ADD_DATA[, YEAR := as.numeric(substr(GBADATUMEINDEADRESHOUDING,1,4))]

ADD_DATA[, LIFEEVENTS_MOVING := ifelse(((paste0(GBADATUMAANVANGADRESHOUDING) == paste0(MIN_YEAR,12,31)) & (paste0(GBADATUMEINDEADRESHOUDING) == paste0(MAX_YEAR,12,31))),0,.N ), by = .(RINPERSOON,YEAR)]

ADD_DATA= ADD_DATA[order(RINPERSOON,YEAR, DIFF)]

ADD_DATA = ADD_DATA[!duplicated(ADD_DATA,by=c("RINPERSOON", "YEAR"),fromLast = T)]

# We also found that there are some people that registered into two address without the same end date. so we choose the longest stay
ADD_DATA$GBADATUMAANVANGADRESHOUDING = as.Date(ADD_DATA$GBADATUMAANVANGADRESHOUDING, format= "%Y%m%d")
ADD_DATA$GBADATUMEINDEADRESHOUDING = as.Date(ADD_DATA$GBADATUMEINDEADRESHOUDING, format= "%Y%m%d")

ADD_DATA = ADD_DATA[, .(YEAR = seq.Date(GBADATUMAANVANGADRESHOUDING,GBADATUMEINDEADRESHOUDING,'year')), by = c("RINOBJECTNUMMER","wc", "bc", "gem", "RINPERSOON", "GBADATUMAANVANGADRESHOUDING", "GBADATUMEINDEADRESHOUDING", "LIFEEVENTS_MOVING") ]

ADD_DATA[,YEAR := as.character(year(YEAR))]


end_time = Sys.time()

end_time - start_time