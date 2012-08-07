module ErrorEnum

	ILLEGAL_EMAIL = -1
	USER_ACTIVATED = -2
	USER_NOT_ACTIVATED = -3
	USER_NOT_EXIST = -4
	ACTIVATE_EXPIRED = -5
	RESET_PASSWORD_EXPIRED = -6
	REQUIRE_LOGIN = -7
	REQUIRE_LOGOUT = -8
	REQUIRE_ADMIN = -9
	WRONG_PASSWORD_CONFIRMATION = -10
	WRONG_PASSWORD = -11
	RECEIVER_CAN_NOT_BLANK = -12
	TITLE_CAN_NOT_BLANK = -13
	CONTENT_CAN_NOT_BLANK = -14
	MESSAGE_NOT_EXIST = -15
	THERE_ARE_SOME_RECEIVERS_NOT_EXIST = -16
	EMAIL_EXIST = -12
	USERNAME_EXIST = -12
	GROUP_EXIST = -20
	GROUP_NOT_EXIST = -21
	UNAUTHORIZED = -22
	SURVEY_NOT_EXIST = -30
	QUESTION_NOT_EXIST = -31
	WRONG_QUESTION_TYPE = -32
	WRONG_QUESTION_CLASS = -33
	OVERFLOW = -34
	WRONG_DATA_TYPE = -40
	THIRD_PARTY_USER_NOT_EXIST = -41 
	THIRD_PARTY_USER_NOT_BIND = -42
	RESOURCE_NOT_EXIST = -50
	WRONG_RESOURCE_TYPE = -51
	MATERIAL_NOT_EXIST = -50
	WRONG_MATERIAL_TYPE = -51
	TAG_EXIST = -60
	TAG_NOT_EXIST = -61
	WRONG_PUBLISH_STATUS = -70
	QUALITY_CONTROL_QUESTION_NOT_EXIST = -80
	QUALITY_CONTROL_QUESTION_NOT_MATCH = -81
	WRONG_QUALITY_CONTROL_QUESTION_ANSWER = -82
	WRONG_QUALITY_CONTROL_TYPE = -83
	REQUIRE_SURVEY_AUDITOR = -90

	QUOTA_RULE_NOT_EXIST = -100
	WRONG_QUOTA_RULE_AMOUNT = -101
	WRONG_QUOTA_RULE_CONDITION_TYPE = -102

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
	SYSTEM_USER_IS_LOCK = 100045
	SYSTEM_USER_MUST_EMAIL_OR_USERNAME =100046

	IP_FORMAT_ERROR = 100101
	IP_REQUEST_SINA_ERROR = 100102
	POSTCODE_REQUEST_BAIDU_ERROR =100103

	USER_SAVE_FAILED = 110000

end

