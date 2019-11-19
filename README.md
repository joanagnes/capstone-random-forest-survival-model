## Detection of Interstitial Lung Disease Using Radiologists' Notes and Medical Claims Data
----------------------------------------------------------------------------------------------

For our capstone project, my MScA partners and I decided to focus on the topic of Interstitial Lung Disease (ILD). 
Our project was comprised of three main components:
1. Automated summarization of radiologists' notes
2. ML model that would predict occurrence of ILD using notes summaries
3. ML survival model that would predict when ILD would occur in members

I focused on the third component, the survival modeling to predict when a patient would receive an ILD diagnosis. The following represents that work.

### Data Prep
I had to execute a fair amount of data cleanup and feature engineering of the raw data to actually use it in a ML model.
The bulk of the work revolved around reducing the multiple rows of data per patient to one row per patient. This included aggregating and ranking patient's health information as well as addressing missing data issues. Also, in order to pass the data through the Random Survival Forest algorithm, I had to one-hot encode many of the categorical data fields.
- SQL files and jupyter notebook show the exact steps that I took

### Building the Random Survival Forest Model
For random survival forest modeling, I used a few packages in R.
First I called the following:
`pes`
`survival`
`party`
`gtools`
`ggplot2`
`survminer`
`dplyr`
`ranger`
And then I called these:
`ggRandomForests`
`randomForestSRC`.

##### Feature Selection
To start, using the ```ranger``` package, I iterated through many different models containing different subsets of all of the available features-- starting with a kitchen sink model. Then I referred to the Variable Importance Plot (VIMP) and was able to see which features were most predictive; I slowly whittled the subset down to the  most explanatory variables-- this was also to cut down on computing time/power needed.
My overall objective was to minimize the error rate, which is outputted by the model.

Below is an example of one of the iterative models that I ran:
```
rf3 <- ranger(Surv(t, censored) ~ gender + race + ethnicity + age_at_last_visit + length_of_first_visit + length_of_last_visit + avg_length_of_all_visits + total_nbr_visits + total_nbr_procs + avg_nbr_procs_per_encounter + total_xr +total_ct + total_other + cigarettes_yn_2 + pipes_yn_2 + cigars_yn_2 + smoking_tob_use_2, data = train7, num.trees=500, importance="impurity", mtry = 12) 
```
Here is a list of the features I ended up using in my model:

<img src="featurelist.png" alt="Features" width="400"/>

##### Hyperparameter Tuning
Once I found the optimal subset of features, I used the ```tune``` feature in the ```randomforestSRC``` package that returns the optimal values for ```mtry``` and ```nodesize```.

```
require(randomForestSRC)
o<- tune(Surv(t, censored)~ gender + race + ethnicity + age_at_last_visit + length_of_first_visit + length_of_last_visit + total_nbr_visits + total_nbr_procs + avg_nbr_procs_per_encounter + total_xr +total_ct + total_other + other_low_resp, data=train7,
  mtryStart = ncol(train7) / 2,  
  nodesizeTry = c(1:9, seq(10, 100, by = 5)), ntreeTry = 50,
  stepFactor = 1.25, improve = 1e-3, strikeout = 3, maxIter = 25,
  trace = FALSE, doBest = TRUE)
```
