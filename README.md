## Detection of Interstitial Lung Disease Using Radiologists' Notes and Medical Claims Data

For our capstone project, my MScA partners and I decided to focus on the topic of Interstitial Lung Disease (ILD). 
Our project was comprised of three main components:
1. Automated summarization of radiologists' notes
2. ML model that would predict occurrence of ILD using notes summaries
3. ML survival model that would predict when ILD would occur in members

I focused on the third component, the survival modeling to predict when a patient would receive an ILD diagnosis. The following represents that work.

### Data Prep
I had to execute a fair amount of data cleanup and feature engineering of the raw data to actually use it in a ML model.
The bulk of the work revolved around reducing the multiple rows of data per patient to one row per patient. This included aggregating and ranking patient's health information as well as addressing missing data issues.
* Please refer to the SQL and jupyter notebook files to see what steps I took.

### Modeling
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


