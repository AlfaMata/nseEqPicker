# ---- Load the library and split data for cross-validation ----
require(caret)
require(nnet)
require(randomForest)
require(e1071) # for fast svm
require(kernlab) # for caret svm

fcd = read.csv('FO.only/FCD.splitadjx.csv', as.is = T)
cutoff = which(fcd$DATE == '2015-04-30')[1]
trainSet = fcd[1:(cutoff-1), -23]
testSet = fcd[cutoff:NROW(fcd), -23]


# ---- Fit classifiers, as many as possible ----

# start with random Forest
rfCtrl = trainControl(method = "cv", number = 2, repeats = 2, verboseIter = T)
rfModel = train(factor(TopPick) ~. - DATE - SYMBOL, data = trainSet, method = 'rf', 
                trControl = rfCtrl, verbose = FALSE)
pred.rf = predict(rfModel$finalModel, testSet)
table(pred.rf)

# rfCtrl2 = trainControl(method = "adaptive_cv", number = 2, repeats = 2, verboseIter = T)
rfModel2 = train(factor(TopPick) ~. - DATE - SYMBOL - arReturns, data = trainSet, 
                 method = 'rf', trControl = rfCtrl, verbose = FALSE)
pred.rf2 = predict(rfModel2$finalModel, testSet)
table(pred.rf2)

# bare bones rf
rfModel3 = randomForest(factor(TopPick) ~. - DATE - SYMBOL - arReturns, data = trainSet)
pred.rf3 = predict(rfModel3, testSet)
table(pred.rf3)

rfModel4 = randomForest(factor(TopPick) ~. - DATE - SYMBOL, data = trainSet)
pred.rf4 = predict(rfModel4, testSet)
table(pred.rf4)


ldaModel = train(factor(TopPick) ~. - DATE - SYMBOL , data = trainSet, method = 'lda')
pred.lda = predict(ldaModel, testSet)

qdaModel = train(factor(TopPick) ~. - DATE - SYMBOL , data = trainSet, method = 'qda')
pred.qda = predict(qdaModel, testSet)

nnetModel = train(factor(TopPick) ~. - DATE - SYMBOL, data=trainSet, method = 'nnet')
pred.nnet = predict(nnetModel, testSet)
table(pred.nnet)

svmModel = e1071::svm(factor(TopPick) ~ . - DATE - SYMBOL, data = trainSet)
pred.svm = predict(svmModel, testSet)
table(pred.svm)

start=proc.time()
svmModel.tuned = e1071::tune.svm(factor(TopPick) ~ . - DATE - SYMBOL, data = trainSet)
proc.time()-start
pred.svm.tuned = predict(svmModel.tuned$best.model, testSet)
table(pred.svm.tuned)


# ---- Time to validate ----
results = cbind(testSet$TopPick, as.character(pred.lda), as.character(pred.qda), 
                as.character(pred.nnet), as.character(pred.rf),
                as.character(pred.svm), as.character(pred.svm.tuned))
colnames(results) = c('testSet', 'pred.lda', 'pred.qda', 
                      'pred.nnet', 'pred.rf', 'pred.svm', 'pred.svm.tuned')
results = as.data.frame(results)

# we want only performance of Top 5 recommendation
intSet = results[results$testSet=='Top', ]
intSet[] <- lapply(intSet, as.character) # convert whole data.frame to char

accuracy = 100* c(sum(intSet$testSet == intSet$pred.lda)/NROW(intSet),
                  sum(intSet$testSet == intSet$pred.qda)/NROW(intSet),
                  sum(intSet$testSet == intSet$pred.nnet)/NROW(intSet),
                  sum(intSet$testSet == intSet$pred.rf)/NROW(intSet),
                  sum(intSet$testSet == intSet$pred.svm)/NROW(intSet),
                  sum(intSet$testSet == intSet$pred.svm.tuned)/NROW(intSet))
