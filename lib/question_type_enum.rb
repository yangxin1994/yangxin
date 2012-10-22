module QuestionTypeEnum
	CHOICE_QUESTION = 0
	MATRIX_CHOICE_QUESTION = 1
	TEXT_BLANK_QUESTION = 2
	NUMBER_BLANK_QUESTION = 3
	EMAIL_BLANK_QUESTION = 4
	URL_BLANK_QUESTION = 5
	PHONE_BLANK_QUESTION = 6
	TIME_BLANK_QUESTION = 7
	ADDRESS_BLANK_QUESTION = 8
	BLANK_QUESTION = 9
	MATRIX_BLANK_QUESTION = 10
	CONST_SUM_QUESTION = 11
	SORT_QUESTION = 12
	RANK_QUESTION = 13
	PARAGRAPH = 14
	FILE_QUESTION = 15
	TABLE_QUESTION = 16
	SCALE_QUESTION = 17


	QUESTION_TYPE_HASH = {
		"0" => "ChoiceQuestion",
		"1" => "MatrixChoiceQuestion",
		"2" => "TextBlankQuestion",
		"3" => "NumberBlankQuestion",
		"4" => "EmailBlankQuesion",
		"5" => "UrlBlankQuestion",
		"6" => "PhoneBlankQuestion",
		"7" => "TimeBlankQuestion",
		"8" => "AddressBlankQuestion",
		"9" => "BlankQuestion",
		"10" => "MatrixBlankQuestion",
		"11" => "ConstSumQuestion",
		"12" => "SortQuestion",
		"13" => "RankQuestion",
		"14" => "Paragraph",
		"15" => "FileQuestion",
		"16" => "TableQuestion"
	}

	BLANK_QUESTION_TYPE = {
		"Text" => TEXT_BLANK_QUESTION,
		"Number" => NUMBER_BLANK_QUESTION,
		"Phone" => PHONE_BLANK_QUESTION,
		"Email" => EMAIL_BLANK_QUESTION,
		"Url" => URL_BLANK_QUESTION,
		"Address" => ADDRESS_BLANK_QUESTION,
		"Time" => TIME_BLANK_QUESTION
	}

end
