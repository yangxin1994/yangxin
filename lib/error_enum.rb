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
	
	TYPE_ERROR = -100001
	RANGE_ERROR = -100002
	SAVE_FAILED = -100004
	ARG_ERROR = -100008
	UNKNOWN_ERROR = -100016
end
