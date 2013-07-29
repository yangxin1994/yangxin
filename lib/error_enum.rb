module ErrorEnum

	REWORD_NOT_SELECTED = "error__10"
	LOTTERY_DRAWED = "error__11"
	NOT_LOTTERY_REWARD = "error__12"

	SAMPLE_ATTRIBUTE_NOT_EXIST = "error__0"
	WRONG_SAMPLE_ATTRIBUTE_TYPE = "error__1"
	WRONG_DATE_TYPE = "error__2"
	SAMPLE_ATTRIBUTE_NAME_EXIST = "error__3"
	SAMPLE_NOT_EXIST = "error__4"
	AGENT_TASK_NOT_EXIST = "error__5"
	WRONG_ORDER_STATUS = "error__6"
	REWARD_NOT_SELECTED = "error__7"
	AGENT_NOT_EXIST = "error__8"
	MOBILE_NOT_EXIST = "error__9"

	
	ANSWER_BOUND = "error__11"
	REPEAT_ORDER = "error__12"
	ANSWER_EXIST = "error__13"

	REWARD_SCHEME_NOT_EXIST = 'error___0'  ##TODO ErrorEnum has not rule yet
	ORDER_TYPE_ERROR = 'error___1'
	ILLEGAL_EMAIL_OR_MOBILE = 'error___2'
	EMAIL_OR_MOBILE_EXIST = 'error___3'
	ACTIVATE_CODE_ERROR   = 'error___4'

	LOGIN_TOO_FREQUENT = "error_0"
	ILLEGAL_EMAIL = "error_1"
	USER_ACTIVATED = "error_2"
	ILLEGAL_ACTIVATE_KEY = "error_02"
	USER_NOT_ACTIVATED = "error_3"
	USER_NOT_EXIST = "error_4"
	USER_NOT_REGISTERED = "error_24"
	USER_REGISTERED = "error_25"
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
	AUTH_KEY_NOT_EXIST = "error_20"
	GROUP_EXIST = "error_21"
	GROUP_NOT_EXIST = "error_22"
	UNAUTHORIZED = "error_23"
	SURVEY_NOT_EXIST = "error_30"
	QUESTION_NOT_EXIST = "error_31"
	WRONG_QUESTION_TYPE = "error_32"
	WRONG_QUESTION_CLASS = "error_33"
	OVERFLOW = "error_34"
	WRONG_DATA_TYPE = "error_40"
	THIRD_PARTY_USER_NOT_EXIST = "error_41"
	THIRD_PARTY_USER_NOT_BIND = "error_42"
	WRONG_THIRD_PARTY_WEBSITE = "error_43"
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
	RANDOM_QUALITY_CONTROL = 'error_87'
	NO_QUALITY_CONTROL = 'error_88'
	REQUIRE_SUPER_ADMIN = "error_90"
	REQUIRE_SURVEY_AUDITOR = "error_91"
	WRONG_USER_ROLE = 'error_92'
	WRONG_USER_COLOR = 'error_93'
	REQUIRE_ANSWER_AUDITOR = 'error_94'
	REQUIRE_ENTRY_CLERK = 'error_95'
	REQUIRE_INTERVIEWER = 'error_96'

	QUOTA_RULE_NOT_EXIST = "error_100"
	WRONG_QUOTA_RULE_AMOUNT = "error_101"
	WRONG_QUOTA_RULE_CONDITION_TYPE = "error_102"
	VIOLATE_QUOTA = "error_103"

	LOGIC_CONTROL_RULE_NOT_EXIST = "error_110"
	WRONG_LOGIC_CONTROL_TYPE = "error_111"

	REQUIRE_INIT_STEP_1 = "error_120"
	REQUIRE_INIT_STEP_2 = "error_121"

	WRONG_QUALITY_CONTROL_QUESTIONS_TYPE = "error_130"

	WRONG_USER_EMAIL = 'error_138'
	REQUIRE_EMAIL_ADDRESS = 'error_139'
	WRONG_SURVEY_PASSWORD = "error_140"
	ANSWER_NOT_EXIST = "error_141"
	VIOLATE_QUALITY_CONTROL_ONCE = "error_142"
	VIOLATE_QUALITY_CONTROL_TWICE = "error_143"

	SURVEY_NOT_PUBLISHED = "error_144"
	SURVEY_CLOSED = "error__145"
	SUEVEY_DELETED = "error__146"
	SURVEY_PASSWORD_USED = "error_145"
	WRONG_ANSWER_STATUS = "error_146"
	SURVEY_NOT_ALLOW_PAGEUP = "error_147"
	ANSWER_NOT_COMPLETE = "error_148"


	WRONG_FILTER_CONDITION_TYPE = "error_150"
	FILTER_NOT_EXIST = "error_151"

	REPORT_MOCKUP_NOT_EXIST = "error_160"
	WRONG_REPORT_MOCKUP_CHART_STYLE = "error_161"
	WRONG_REPORT_MOCKUP_COMPONENT_TYPE = "error_162"
	WRONG_REPORT_TYPE = "error_163"
	WRONG_REPORT_STYLE = "error_164"

	RESULT_NOT_EXIST = 'error_170'
	DATA_LIST_NOT_EXIST = 'error_171'

	ANSWER_NOT_FINISHED = 'error_180'
	ANSWER_REVIEWED = 'error_181'

	TASK_NOT_EXIST = 'error_190'
	TASK_TIMEOUT = 'error_191'
	TASK_CREATION_FAILED = 'error_200'
	TASK_DESTROY_FAILED = 'error_201'

	DOTNET_TIMEOUT = 'error_210'
	DOTNET_SERVICE_REFUSED = 'error_211'
	DOTNET_HTTP_ERROR = 'error_212'
	DOTNET_INTERNAL_ERROR = 'error_213'

	# lcm add for answer review
	REWARD_ERROR = 'error_300'

	INTERVIEWER_NOT_EXIST = 'error_301'
	INTERVIEWER_TASK_NOT_EXIST = 'error_302'

	# extension error
	BROWSER_EXTENSION_NOT_EXIST = 'error_400'
	BROWSER_NOT_EXIST = 'error_401'

	UNKNOWN_ERROR = "error_100000"
	SAVE_ERROR = "error_200000"
	FAQ_TYPE_ERROR = "error_100001"
	FAQ_RANGE_ERROR = "error_100002"
	FAQ_SAVE_FAILED = "error_100003"
	FAQ_NOT_EXIST = "error_100004"
	PUBLIC_NOTICE_STATUS_ERROR = "error_100011"
	PUBLIC_NOTICE_SAVE_FAILED = "error_100013"
	PUBLIC_NOTICE_NOT_EXIST = "error_100014"
	FEEDBACK_TYPE_ERROR = "error_100021"
	FEEDBACK_RANGE_ERROR = "error_100022"
	FEEDBACK_SAVE_FAILED = "error_100023"
	FEEDBACK_NOT_EXIST = "error_100024"
	FEEDBACK_NO_QUESTION_USER = "error_100025"
	FEEDBACK_NOT_CREATOR = "error_100026"
	FEEDBACK_CANNOT_UPDATE = "error_100027"
	FEEDBACK_CANNOT_DELETE = "error_100028"
	ADVERTISEMENT_TYPE_ERROR = "error_100031"
	ADVERTISEMENT_RANGE_ERROR = "error_100032"
	ADVERTISEMENT_SAVE_FAILED = "error_100033"
	ADVERTISEMENT_NOT_EXIST = "error_100034"
	ADVERTISEMENT_TITLE_EXIST = "error_100035"
	SYSTEM_USER_TYPE_ERROR = "error_100041"
	SYSTEM_USER_RANGE_ERROR = "error_100042"
	SYSTEM_USER_SAVE_FAILED = "error_100043"
	SYSTEM_USER_NOT_EXIST = "error_100044"
	SYSTEM_USER_IS_LOCK = "error_100045"
	SYSTEM_USER_MUST_EMAIL_OR_USERNAME = "error_100046"
	USER_LOCKED = "error_100047"

	IP_FORMAT_ERROR = "error_100101"
	IP_REQUEST_SINA_ERROR = "error_100102"
	POSTCODE_REQUEST_BAIDU_ERROR = "error_100103"

	SURVEY_DEADLINE_ERROR = "error_110001"

###
# 	syetem error 1
# 	error 2
#
# 	not_found 01
# 	invalid_id 02
#
# 	blank x0
#   not a number x1
###

	# Gifts Error Code (10)
	GIFT_NOT_FOUND = "error_21001"

	INVALID_GIFT_ID = "error_21002"

	GIFT_QUANTITY_NOT_A_NUNBER = "error_21031"
	GIFT_SURPLUS_NOT_A_NUNBER = "error_21041"
	GIFT_NOT_ENOUGH = "error_21033"
	GIFT_POINT_COULD_NOT_BE_BLANK = "error_21020"
	GIFT_POINT_NOT_A_NUNBER = "error_21021"
	# Messages Error Code (11)
	MESSAGE_NOT_FOUND = "error_21101"
	INVALID_MESSAGE_ID = "error_21102"
	MESSAGE_TITLE_COULD_NOT_BE_BLANK = "error_21110"
	MESSAGE_CONTENT_COULD_NOT_BE_BLANK = "error_21120"
	# Prize Error Code (12)
	PRIZE_NOT_ENOUGH = "error_21233"
	PRIZE_NOT_FOUND = "error_21201"
	PRIZE_CTRL_PARAMS_ERROR = "error_21207"
	# RewardLog Error Code (13)
	REWARDLOG_POINT_NOT_A_NUNBER = "error_21311"
	# Order Error Code (14)
	ORDER_NOT_FOUND = "error_21401"
	INVALID_ORDER_ID = "error_21402"
	ORDER_TYPE_NOT_A_NUNBER = "error_21411"
	ORDER_STATUS_NOT_A_NUNBER = "error_21421"
	ORDER_STATUS_COULN_NOT_BE_BLANK = "error_21420"
	ORDER_TYPE_COULN_NOT_BE_BLANK = "error_21430"
	ORDER_CAN_NOT_BE_UPDATED = "error_11400"
	ORDER_CAN_NOT_BE_CANCELED = "error_11403"
	# Prize Error Code (15)
	INVALID_PRIZE_ID = "error_21501"
	# Lottery Error Code (16)
	INVALID_LOTTERY_ID = "error_21602"
	LOTTERY_CANNOT_EXCHANGE  = "error_21632"
	# Lottery Code Error Code (17)
	LOTTERYCODE_NOT_FOUND = "error_21701"
	INVALID_LOTTERYCODE_ID = "error_21702"
	USER_SAVE_FAILED = "error_110000"
	# Point Error (18)
	POINT_NOT_ENOUGH = "error_21833"
	# User Error (20)
	USER_NOT_FOUND = "error_22001"
	# Answer Error (21)
	WRONG_ANSWERS = "error_121031"
	# Photo Errot (22)
	PHOTP_CANNOT_BE_BLANK = "error_122201"
end

