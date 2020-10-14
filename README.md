# Gravity_of_Intermediate_Goods_RIO2020

This repository contains all codes to replicate the empirical results in "The Gravity of Intermediate Goods" - Review of Industrial Organization (2020) by Paola Conconi, Glenn Magerman and Afrola Plaku.
Feel free to send a line to [glenn.magerman@ulb.be](glenn.magerman@ulb.be) for any questions or comments.

Data for the project is obtained from the following sources:
  1. Gravity data from [BACI/CEPII](http://www.cepii.fr/cepii/en/bdd_modele/presentation.asp?id=1)
  2. Classification of goods by [Jim Rauch](http://econweb.ucsd.edu/~jrauch/rauchclass/SITCRauch_merging_code.do)
  3. HS classification from [UN](http://unstats.un.org/unsd/tradekb/Knowledgebase/50043/HS-Classification-by-Section)
  4. HS to BEC classificatin from [UN](http://unstats.un.org/unsd/trade/classifications/correspondence-tables.asp)

			
All code is written in Stata, and all do-files are available in this repo.
After downloading the relevant datasets, just run these Stata codes to generate the output in the paper.

Some important notes:
  1. You might need a Comtrade license to get access to the BACI/CEPII trade datasets.
  2. Creating the dataset with all possible zeroes at the country-pair-HS6-year level and running the PPML models including zeroes are resource intensive, and most probably
  fail on standard machines. We used a server with 36 cores and 1 TB Ram to run the large panel with zeroes.

Paola, Glenn and Afrola
  
