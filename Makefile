.PHONY: admob_id

admob_id:
	@echo "AD_UNIT_ID = ${AD_UNIT_ID}" > ./WakeApp/Config.xcconfig
	@echo "GAD_APP_IDENTIFIER = ${GAD_APP_IDENTIFIER}" >> ./WakeApp/Config.xcconfig


