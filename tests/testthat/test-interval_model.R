test_that("assert_choose_params_auc_choices", {
  # no parameters are required
  expect_equal(
    assert_choose_params_auc_choices(auc_choices = NULL),
    character()
  )
  # multiple parmaeters may be returned
  expect_equal(
    assert_choose_params_auc_choices(auc_choices = c("last", "all", "inf"), route = "intravascular", clast_type = "pred", auc_prefix = "auc"),
    c("aucivlast", "aucivall", "aucivinf.pred")
  )
  # Verify that all valid choices return valid parameter names
  for (current_auc_choices in c("all", "inf", "last")) {
    for (current_route in c("extravascular", "intravascular")) {
      for (current_clast_type in c("pred", "obs")) {
        for (current_auc_prefix in c("auc", "aumc")) {
          # TODO: multiple AUMC IV parameters do not exist
          if (current_auc_prefix == "aumc" && current_route == "intravascular") {
            expect_error(
              assert_choose_params_auc_choices(
                auc_choices = current_auc_choices,
                route = current_route,
                clast_type = current_clast_type,
                auc_prefix = current_auc_prefix
              ),
              regexp = "not .*valid PKNCA parameter name"
            )
          } else {
            expect_error(
              assert_choose_params_auc_choices(
                auc_choices = current_auc_choices,
                route = current_route,
                clast_type = current_clast_type,
                auc_prefix = current_auc_prefix
              ),
              NA
            )
          }
        }
      }
    }
  }
  expect_equal(
    assert_choose_params_auc_choices(auc_choices = "inf", route = "extravascular", clast_type = "pred", auc_prefix = "auc"),
    "aucinf.pred"
  )
})
