module ErrorEnum

	LOGIN_TOO_FREQUENT = "error_0"
	ILLEGAL_EMAIL = "error_1"
	USER_ACTIVATED = "error_2"
	USER_NOT_ACTIVATED = "error_3"
	USER_NOT_EXIST = "error_4"
	ACTIVATE_EXPIRED = "error_5"
	RESET_PASSWORD_EXPIRED = "error_6"
	REQUIRE_LOGIN = "error_7"
	REQUIRE_LOGOUT = "error_8"
	REQUIRE_ADMIN = "error_9"
	WRONG_PASSWORD_CONFIRMATION = "error_10"
	WRONG_PASSWORD = "error_11"
	RECEIVER_CAN_NOT_BLANK = "error_12"
	TITLE_CAN_NOT_BLANK = "error_13"
	CONTENT_CAN_NOT_BLANK = "error_14"
	MESSAGE_NOT_EXIST = "error_15"
	THERE_ARE_SOME_RECEIVERS_NOT_EXIST = "error_16"
	EMAIL_EXIST = "error_17"
	USERNAME_EXIST = "error_18"
	AUTH_KEY_EXIST = "error_19"
	GROUP_EXIST = "error_20"
	GROUP_NOT_EXIST = "error_21"
	UNAUTHORIZED = "error_22"
	SURVEY_NOT_EXIST = "error_30"
	QUESTION_NOT_EXIST = "error_31"
	WRONG_QUESTION_TYPE = "error_32"
	WRONG_QUESTION_CLASS = "error_33"
	OVERFLOW = "error_34"
	LOGIC_CONTROL_CONFLICT_DETECTED = "error_35"
	WRONG_DATA_TYPE = "error_40"
	THIRD_PARTY_USER_NOT_EXIST = "error_41"
	THIRD_PARTY_USER_NOT_BIND = "error_42"
	MATERIAL_NOT_EXIST = "error_50"
	WRONG_MATERIAL_TYPE = "error_51"
	TAG_EXIST = "error_60"
	TAG_NOT_EXIST = "error_61"
	WRONG_PUBLISH_STATUS = "error_70"
	QUALITY_CONTROL_QUESTION_NOT_EXIST = "error_80"
	QUALITY_CONTROL_QUESTION_NOT_MATCH = "error_81"
	WRONG_QUALITY_CONTROL_QUESTION_ANSWER = "error_82"
	WRONG_QUALITY_CONTROL_TYPE = "error_83"
	QUALITY_CONTROL_QUESTION_ANSWER_NOT_EXIST = "error_84"
	MATCHING_NOT_EXIST = "error_85"
	TEMPLATE_QUESTION_NOT_EXIST = "error_86"
	REQUIRE_SURVEY_AUDITOR = "error_90"

	QUOTA_RULE_NOT_EXIST = "error_100"
	WRONG_QUOTA_RULE_AMOUNT = "error_101"
	WRONG_QUOTA_RULE_CONDITION_TYPE = "error_102"

	LOGIC_CONTROL_RULE_NOT_EXIST = "error_110"
	WRONG_LOGIC_CONTROL_TYPE = "error_111"

	REQUIRE_INIT_STEP_1 = "error_120"
	REQUIRE_INIT_STEP_2 = "error_121"

	WRONG_QUALITY_CONTROL_QUESTIONS_TYPE = "error_130"

	UNKNOWN_ERROR = -100000
	FAQ_TYPE_ERROR = -100001
	FAQ_RANGE_ERROR = -100002
	FAQ_SAVE_FAILED = -100003
	FAQ_NOT_EXIST = -100004
	PUBLIC_NOTICE_TYPE_ERROR = -100011
	PUBLIC_NOTICE_RANGE_ERROR = -100012
	PUBLIC_NOTICE_SAVE_FAILED = -100013
	PUBLIC_NOTICE_NOT_EXIST = -100014
	FEEDBACK_TYPE_ERROR = -100021
	FEEDBACK_RANGE_ERROR = -100022
	FEEDBACK_SAVE_FAILED = -100023
	FEEDBACK_NOT_EXIST = -100024
	FEEDBACK_NO_QUESTION_USER = -100025
	FEEDBACK_NOT_CREATOR = 100026
	FEEDBACK_CANNOT_UPDATE =100027
	FEEDBACK_CANNOT_DELETE = 100028
	ADVERTISEMENT_TYPE_ERROR = -100031
	ADVERTISEMENT_RANGE_ERROR = -100032
	ADVERTISEMENT_SAVE_FAILED = -100033
	ADVERTISEMENT_NOT_EXIST = -100034
	ADVERTISEMENT_TITLE_EXIST = -100035
	SYSTEM_USER_TYPE_ERROR = -100041
	SYSTEM_USER_RANGE_ERROR = -100042
	SYSTEM_USER_SAVE_FAILED = -100043
	SYSTEM_USER_NOT_EXIST = -100044
	SYSTEM_USER_IS_LOCK = -100045
	SYSTEM_USER_MUST_EMAIL_OR_USERNAME = -100046

	IP_FORMAT_ERROR = -100101
	IP_REQUEST_SINA_ERROR = -100102
	POSTCODE_REQUEST_BAIDU_ERROR = -100103

	SURVEY_DEADLINE_ERROR = -110001

###
# 	syetem error 1
# 	error 2
# 	not_found 01
# 	invalid_id 02
#
# 	blank x0
#   not a number x1
###

	# Presents Error Code (10)
	PRESENT_NOT_FOUND= 21001
	INVALID_PRESENT_ID = 21002
	# Messages Error Code (11)
	MESSAGE_NOT_FOUND = 21101
	INVALID_MESSAGE_ID = 21102
	MESSAGE_TITLE_COULD_NOT_BE_BLANK = 21110
	MESSAGE_CONTENT_COULD_NOT_BE_BLANK = 21120
	# Award Error Code (12)
	AwardBudgetCounldNotBeBlank = 21211
	# PointLog Error Code (13)
	POINTLOG_OPERATED_POINT_NOT_A_NUNBER = 21311
	# Order Error Code (14)
	ORDER_NOT_FOUND = 21401
	INVALID_ORDER_ID = 21402
	ORDER_TYPE_NOT_A_NUNBER = 21411
	ORDER_STATUS_NOT_A_NUNBER = 21412
	ORDER_TYPE_COULN_NOT_BE_BLANK = 21413
	USER_SAVE_FAILED = 110000

end

