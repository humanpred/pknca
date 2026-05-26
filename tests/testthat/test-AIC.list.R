test_that("AIC.list", {
  tmpdat <- data.frame(x=c(1, 2, 3), y=c(1, 2.02, 3), z=c(0, 0.01, 0))
  mod1 <- glm(y~x, data=tmpdat)
  mod2 <- glm(y~x+z, data=tmpdat)
  d1 <- list(list(mod1), mod2)
  result1 <- data.frame(AIC=c(as.numeric(AIC(mod1)), as.numeric(AIC(mod2))),
                        df=c(3, 4),
                        indentation=c(1, 0),
                        isBest=c("", "Best Model"),
                        stringsAsFactors=FALSE)
  expect_equal(AIC.list(d1), result1)

  # Check that simple names apply correctly
  d2 <- list(list("A"=mod1), "B"=mod2)
  result2 <- data.frame(AIC=c(as.numeric(AIC(mod1)), as.numeric(AIC(mod2))),
                        df=c(3, 4),
                        indentation=c(1, 0),
                        isBest=c("", "Best Model"),
                        stringsAsFactors=FALSE,
                        row.names=c("A", "B"))
  expect_equal(AIC.list(d2), result2)

  d3 <- list("A"=mod1, "B"=mod2)
  result3 <- data.frame(AIC=c(as.numeric(AIC(mod1)), as.numeric(AIC(mod2))),
                        df=c(3, 4),
                        indentation=c(0, 0),
                        isBest=c("", "Best Model"),
                        stringsAsFactors=FALSE,
                        row.names=c("A", "B"))
  expect_equal(AIC.list(d3), result3)
  
  d4 <- list("C"=list("A"=mod1), "B"=mod2)
  result4 <- data.frame(AIC=c(as.numeric(AIC(mod1)), as.numeric(AIC(mod2))),
                        df=c(3, 4),
                        indentation=c(1, 0),
                        isBest=c("", "Best Model"),
                        stringsAsFactors=FALSE,
                        row.names=c("C A", "B"))
  expect_equal(AIC.list(d4), result4)

  d5 <- list("C"=list("A"=mod1), "B"=mod2, C=NA)
  result5 <- data.frame(AIC=c(as.numeric(AIC(mod1)), as.numeric(AIC(mod2)), NA),
                        df=c(3, 4, NA),
                        indentation=c(1, 0, 0),
                        isBest=c("", "Best Model", ""),
                        stringsAsFactors=FALSE,
                        row.names=c("C A", "B", "C"))
  expect_equal(AIC.list(d5), result5)

})

test_that("get.best.model", {
  tmpdat <- data.frame(x=c(1, 2, 3), y=c(1, 2.02, 3), z=c(0, 0.01, 0))
  mod1 <- glm(y~x, data=tmpdat)
  mod2 <- glm(y~x+z, data=tmpdat)
  d1 <- list(list(mod1), mod2)
  expect_equal(get.best.model(d1), mod2)
})
