rm(list=ls())
install.packages("ISLR2")
library(MASS)
library(usmap)
library(ggplot2)
library(gridExtra)
library(gcookbook)
library(ISLR2)
install.packages("gcookbook")
data()

data.arrests = USArrests
data = statepop
full = row.names(data.arrests)
data1 = cbind(full, data.arrests)
data2 = merge(data, data1)

plot_usmap(data = data2, values = "Murder") + 
  scale_fill_continuous(low = "white", high = "red", name = "Murder Rates", label = scales::comma) +
  theme(legend.position = "right")

plot_usmap(data = data2, values = "Assault") + 
  scale_fill_continuous(low = "white", high = "red", name = "Assault Rates", label = scales::comma) +
  theme(legend.position = "right")

plot_usmap(data = data2, values = "UrbanPop") + 
  scale_fill_continuous(low = "darkgray", high = "black", name = "Urban Population", label = scales::comma) +
  theme(legend.position = "right")

foo = data.arrests$Murder + data.arrests$Assault + data.arrests$Rape
data2$total = foo

plot_usmap(data = data2, values = "total") + 
  scale_fill_continuous(low = "black", high = "lavender", name = "Total Arrests", label = scales::comma) +
  theme(legend.position = "right")

cor(data2$total, data2$Murder)
#Watch out for pairwise vs. Partial/Conditional Correlations#

summary(data2$Murder)
sd(data2$Assault)
sd(data2$Murder)
sd(data2$Rape)

#Difference between Sort and Order, where Order provides the index and sort provides the values#
sort(data.arrests$Murder)
order(data.arrests$Murder)

rm(list=ls())
data.iris = iris
table(data.iris$Species)

#Flower-Specific Summaries#
summary(data.iris[data.iris$Species=="setosa",1])

data.marathon = marathon

p = ggplot(data.marathon, aes(x = Half, y = Full)) + geom_point() + coord_fixed(1/2)

data.pop = uspopage
yrs = unique(data.pop$Year)
tot = rep(NA, length(yrs))
for (i in 1:length(yrs)){
  foo = subset(data.pop, Year == yrs[i])
  tot[i] = sum(foo$Thousands)
}
data.poptot = data.frame(yrs, tot)

p2 = ggplot(data.poptot, aes(x = yrs, y = tot))
p2 + geom_area()

data.pop1 = data.pop
data.pop1$AgeGroup = factor(data.pop$AgeGroup, levels = rev(levels(data.pop$AgeGroup)))

#Stacked Area Plot#
p3 = ggplot(data.pop1, aes(x = Year, y = Thousands, fill = AgeGroup))
p3 + geom_area()
##Class Session 2-3##
help(read.csv)
setwd("C:/Users/harri/Downloads")
bike.data = read.csv("Lec3_nc_bike_crash.csv", stringsAsFactors = T, sep = ";")
bike.data = bike.data[,-c(1,2)]
table(bike.data$AmbulanceR)
names(bike.data)[1] = "Ambulatance_Req"
table(bike.data$BikeAge_Gr)
levels(bike.data$BikeAge_Gr)[2] = "0-5"
levels(bike.data$BikeAge_Gr)[3] = "6-10"
levels(bike.data$BikeAge_Gr)[4] = "11-15"
levels(bike.data$BikeAge_Gr)[12] = levels(bike.data$BikeAge_Gr)[13]
levels(bike.data$BikeAge_Gr)[1] = NA

a = bike.data$Location
a = as.character(a)
a = strsplit(a, split = ",")
a = unlist(a)
a = matrix(as.numeric(a), nrow = nrow(bike.data), ncol = 2, byrow = T)
a = as.data.frame(a)
bike.data = cbind(bike.data, a)
library(ggplot2)
ggplot(bike.data, aes(x=V2, y = V1, color = Region)) + geom_point()
ggplot(bike.data, aes(x=V2, y = V1, color = Rural_Urba)) + geom_point()
bike.data$V2[which(bike.data$V2==0)] = NA
bike.data$V1[which(bike.data$V1==0)] = NA

ggplot(bike.data, aes(x = Region, y = Drvr_Age, fill = Region)) + geom_boxplot() #Driver Age Boxplot#
ggplot(bike.data, aes(x = Region, y = Bike_Age, fill = Region)) + geom_violin() #Biker Age Violin Plots#

ggplot(bike.data, aes(x = BikeAge_Gr, fill = Region )) + geom_bar()

table(bike.data$Crash_Date)     
table(bike.data$CrashDay)
weekdays(as.Date("2025-01-15"))
bike.data$CrashDay = weekdays(as.Date(bike.data$Crash_Date))
bike.data$CrashDay
table(bike.data$CrashDay)
levels(bike.data$CrashDay)

crashcounter = matrix(nrow = nrow(bike.data), ncol = 1)
for (i in 1:nrow(bike.data)){
  crashcounter[i, 1] = 1
}
##WEEK 3/4##
###Linear Regression!!!###
lm.fit = lm(medv~lstat, data = Boston)
summary(lm.fit)

#Confidence Interval Viewing#
confint(lm.fit, level = 0.9)

#To view specific prediction values#
predict(lm.fit, data.frame(lstat = c(5, 10, 15)))
#When viewed, it is shown how lstat has a negative association with house values#

attach(Boston)
plot(lstat, medv, pch = 61)
abline(lm.fit, lwd = 3, col = "green")

#This allows us to check diagnostic plots#
plot(lm.fit)

#A multiple linear regression approach#
summary(lm(medv ~., data = Boston))

#A look into interaction terms#
summary(lm(medv ~ lstat*age, data = Boston))

data_default = Default
p1 = ggplot(data_default, aes(x = balance, y = default, fill = default)) + geom_boxplot()
p3 = ggplot(data_default, aes(x = income, y = default, fill = default)) + geom_boxplot()
grid.arrange(p1,p3,nrow=1, ncol=2)
p2 = ggplot(data_default, aes(x = balance, y = default, color = student)) + geom_point()

table(data_default$student, data_default$default)

fit1 = glm(default ~ balance, data = data_default, family = "binomial")
fit2 = glm(default ~ income, data = data_default, family = "binomial")
summary(fit1)
summary(fit2)
?fisher.test
fullfit = glm(default ~ ., data = data_default, family = "binomial")
summary(fullfit)

nullfit = glm(default ~ 1, data =  data_default, family = "binomial")
foo = stepAIC(nullfit, dirrection = "both", scope = list(upper = fullfit, lower = nullfit))

fit.best = glm(formula(foo), data = data_default, family = "binomial")
summary(fit.best)

##CLASSIFICATION##

glm_fits = glm(Direction ~ Lag1 + Lag2 + Lag3 + Lag4 + Lag5 + Volume, data = Smarket, family = "binomial")
summary(glm_fits)
glm.probs = predict(glm_fits, type = "response")
table(Smarket$Direction)

data(Smarket)
newSmarket = Smarket
glm.pred = rep("Down", 1250)
glm.pred[glm.probs > 0.5] = "Up"
newSmarket$Index = as.numeric(1:1250)
newSmarket$numprobs = as.numeric(glm.probs)
ggplot(data = newSmarket, aes(x = Index, y = glm.probs, color = Direction)) + geom_point()

table(glm.pred, Smarket$Direction)
145/(145+457)
#SPECIFICITY OF 24%
507/(141+507)
#SENSITIVITY OF 78%
train = subset(Smarket, Year < 2005)
test = subset(Smarket, Year >= 2008)
glm.fits = glm(Direction ~ Lag1 + Lag2 + Lag3 + Lag4 + Lag5 + Volume, data = train, family = "binomial")
glm.probs = predict(glm.fits, test, type = "response")
glm.pred = rep("Down", 252)
glm.pred[glm.probs > 0.5] = "Up"

table(glm.pred, test$Direction)

#Select a certain set of variables, as LogReg doesn't always enjoy overfitting#
newpred = glm(Direction ~ Lag1 + Lag2, data = train, family = "binomial")
glm.probs = predict(newpred, test, type = "response")
glm.pred = rep("Down", 252)
glm.pred[glm.probs > 0.5] = "Up"
table(glm.pred, test$Direction)

#LDA such#
LDAstock = lda(Direction ~ Lag1 + Lag2, data = train)
summary(LDAstock)
LDAstock #I truthfully have no idea what this output is#
LDApred = predict(LDAstock, test)
LDAclass = LDApred$class
table(LDAclass, test$Direction)

#QDA - Quadratic Discriminatory Analysis#
QDAstock = qda(Direction ~ Lag1 + Lag2, data = train)
summary(QDAstock)
QDAstock #I truthfully have no idea what this output is#
QDApred = predict(QDAstock, test)
QDAclass = QDApred$class
table(QDAclass, test$Direction)

#Naive Bayes in R#
library(e1071)
nb.fit = naiveBayes(Direction ~ Lag1 + Lag2, data = train)
nb.class = predict(nb.fit, test)
table(nb.class, test$Direction)

#Some setup for KNN#
library(class)
attach(Smarket)

train.x = cbind(Lag1, Lag2)[1:998,]
test.x = cbind(Lag1, Lag2)[!(1:998),]
train.Direction = Smarket$Direction[1:998]
knnpred = knn(train.x, test.x, train.Direction, k = 1)
table(knnpred, test$Direction)

#SVM looks like QDA setup#

##PARALLEL COMPUTING AND DECISION TREEING##
library(MASS)
library(e1071)
library(class)

data.iris = iris
K=1000
n = nrow(iris)
train.prop = 0.4
train.size = ceiling(n*train.prop)
test.size = n - train.size

lda.err.cv = rep(NA,K)
qda.err.cv = rep(NA,K)
svm.err.cv = rep(NA,K)
knn.err.cv = rep(NA,K)

ptm1 = proc.time()
for (i in 1:K){
  print(i)
  foo = sample(n, train.size)
  train.data = data.iris[foo,]
  test.data = data.iris[-foo,]
  
  lda.cv = lda(Species~., data = train.data)
  qda.cv = qda(Species~., data = train.data)
  svm.cv = svm(Species~., data = train.data)
  knn.cv = lda(Species~., data = train.data)
  
  pred.lda = predict(lda.cv, test.data)
  pred.qda = predict(qda.cv, test.data)
  pred.svm = predict(svm.cv, test.data)
  knn.pred = knn(train = train.data[,1:4], test = test.data[,1:4], cl = train.data$Species, k = 10)
  lda.err.cv[i] = sum(test.data$Species != pred.lda$class)/nrow(test.data)
  qda.err.cv[i] = sum(test.data$Species != pred.qda$class)/nrow(test.data)
  svm.err.cv[i] = sum(test.data$Species != pred.svm)/nrow(test.data)
  knn.err.cv[i] = sum(test.data$Species != knn.pred)/nrow(test.data)
}
ptm2 = proc.time()
print(ptm2 - ptm1)
#Parallelization#

install.packages("doParallel")
library(doParallel)
detectCores()
cl = makeCluster(8)
registerDoParallel(cl)

#Run the below code#

ptm1 = proc.time()
results = foreach(isim = 1:K, .combine = rbind, .packages = c("e1071", "MASS", "class")) %dopar%{
  foo = sample(n, train.size)
  train.data = data.iris[foo,]
  test.data = data.iris[-foo,]
  
  lda.cv = lda(Species~., data = train.data)
  qda.cv = qda(Species~., data = train.data)
  svm.cv = svm(Species~., data = train.data)
  knn.cv = lda(Species~., data = train.data)
  
  pred.lda = predict(lda.cv, test.data)
  pred.qda = predict(qda.cv, test.data)
  pred.svm = predict(svm.cv, test.data)
  knn.pred = knn(train = train.data[,1:4], test = test.data[,1:4], cl = train.data$Species, k = 10)
  lda.err.cv = sum(test.data$Species != pred.lda$class)/nrow(test.data)
  qda.err.cv = sum(test.data$Species != pred.qda$class)/nrow(test.data)
  svm.err.cv = sum(test.data$Species != pred.svm)/nrow(test.data)
  knn.err.cv = sum(test.data$Species != knn.pred)/nrow(test.data)
  
  c(lda.err.cv, qda.err.cv, svm.err.cv, knn.err.cv)
}

ptm2 = proc.time()
print(ptm2 - ptm1)

colnames(results) = c("LDA", "QDA", "SVM", "KNN")
results = as.data.frame(results)
summary(results)

#TREES AND FORESTS CODE#
library(tree)
library(ISLR2)
attach(Carseats)

High = factor(ifelse(Sales <= 8, "No", "Yes"))
table(High)

Carseats = data.frame(Carseats, High)
Carseats = Carseats[,-1]
tree.carseats = tree(High ~.,Carseats)
summary(tree.carseats)
plot(tree.carseats)
text(tree.carseats, pretty = 1)

#This gives test error, let's create the cross-validation data set and find that error#
train = sample(1:nrow(Carseats), 200)
carseats.test = Carseats[-train,]
High.test = High[-train]
tree.carseats = tree(High~.,Carseats, subset = train)
tree.pred = predict(tree.carseats, carseats.test, type = "class")
table(tree.pred, High.test)
44/200 #The cross validation error#

cv.carseats = cv.tree(tree.carseats, FUN = prune.misclass)
par(mfrow=c(1,2))
plot(cv.carseats$size, cv.carseats$dev, type= "b")
plot(cv.carseats$k, cv.carseats$dev, type= "b")
summary(cv.carseats$dev)

prune.carseats = prune.misclass(tree.carseats, best = 13)
plot(prune.carseats)
text(prune.carseats, pretty = 2)
tree.pred = predict(prune.carseats, carseats.test, type = "class")
table(tree.pred, High.test)

train = sample(1:nrow(Boston), nrow(Boston)/2)
tree.boston = tree(medv~., Boston, subset = train)
plot(tree.boston)
text(tree.boston, pretty = 1)
summary(tree.boston)

library(randomForest)
bag.boston = randomForest(medv~., data = Boston, subset = train, mtry = 12, importance = TRUE)
plot(bag.boston)
yhat.bag = predict(bag.boston, newdata = Boston[-train,])
mean((yhat.bag-Boston$medv[-train])^2)

rf.boston = randomForest(medv~., data = Boston, subset = train, mtry = 4, importance = TRUE)
yhat.rf = predict(rf.boston, newdata = Boston[-train,])
mean((yhat.rf-Boston$medv[-train])^2)


?AIC
varImpPlot(rf.boston)

install.packages("gbm")
library(gbm)
boost.boston = gbm(medv~., data = Boston[train,], distribution = "gaussian", n.trees = 500, interaction.depth = 4)
yhat.boost = predict(boost.boston, newdata = Boston[-train,],n.trees = 500)
mean((yhat.boost-Boston$medv[-train])^2)

importance(boost.boston)

for (bruh in 1:100){
  knnpred = knn(train.x, test.x, train.Direction, k = bruh)
  print(table(knnpred, test$Direction)[1,1] + table(knnpred, test$Direction)[2,2])
}


#UNSUPERVISED LEARNING#
states = row.names(USArrests)
apply(USArrests, 2, mean)
apply(USArrests, 2, var)

pr.out = prcomp(USArrests, scale = T)
names(pr.out)

biplot(pr.out, scale = 0)

pr.out$sdev
sum(pr.out$sdev^2) #This makes sense as all the variation is explained through these 4 variables

pr.var = pr.out$sdev^2
pve = pr.var/sum(pr.var)
plot(pve) #Shows the proportion of variance each PrinComp gives#
cumsum(pve)

library(softImpute)
X = data.matrix(scale(USArrests))
nomit = 5
ina = sample(seq(50), nomit)
inb = sample(1:4, nomit, replace = T)
Xna = X
index.na = cbind(ina, inb)
Xna[index.na] = NA
fits = softImpute(Xna, trace= T, type = "svd")
xhat = complete(Xna, fits)
cor(xhat[index.na],X[index.na])

#Clustering/Kmeans Analysis#
library(ggplot2)
library(ISLR2)

x = matrix(rnorm(50*2), ncol = 2)
x[1:25,1] = x[1:25,1] + 3
x[1:25,2] = x[1:25,2] - 4
plot(x, pch = 16)

km.out = kmeans(x, 3, nstart = 20)
km.out$cluster

a = as.data.frame(cbind(km.out$cluster, x))
ggplot(a, aes(x = V2, y = V3, colour = V1)) + geom_point(size = 3)

hc.complete = hclust(dist(x), method = "complete")
hc.avg = hclust(dist(x), method = "average")
hc.single = hclust(dist(x), method = "single")
hc.cent = hclust(dist(x), method = "centroid")

par(mfrow = c(1,4))
plot(hc.complete)
plot(hc.avg)
plot(hc.cent)
plot(hc.single)

cutree(hc.complete, 4)

nci.labs = NCI60$labs
nci.data = NCI60$data

scaled_nci = scale(nci.data)
data.dist = dist(scaled_nci)
par(mfrow = c(1,3))
plot(hclust(dist(data.dist), method = "complete"))
plot(hclust(dist(data.dist), method = "single"))
plot(hclust(dist(data.dist), method = "average"))

km.out = kmeans(scaled_nci, 4, nstart = 20)
km.clusters = km.out$cluster
table(km.clusters, cutree(hclust(data.dist, method = "complete"),4))


##Association Rules##
x1 = mtcars$cyl
x2 = mtcars$vs

data.table = table(x1, x2)
chisq.test(data.table)
fisher.test(data.table)

data.ucb = UCBAdmissions
table.ucb = margin.table(data.ucb, c(1,2))
#At this level, it appears that there is gender-based discrimination#

dept = c("A", "B", "C", "D", "E", "F")
admit = matrix(0, nrow = 6, ncol = 2)
for (i in 1:6){
  foo = data.ucb[,,i]
  admit[i,1] = foo[1,1]/(foo[1,1]+foo[2,1])
  admit[i,2] = foo[1,2]/(foo[1,2]+foo[2,2])
}
row.names(admit) = dept
colnames(admit) = c("M", "F")
round(admit,3)

mantelhaen.test(UCBAdmissions)
  