class Issue

	ISSUE_TYPE = %w[ChoiceIssue MatrixChoiceIssue TextBlankIssue NumberBlankIssue EmailBlankIssue UrlBlankIssue PhoneBlankIssue TimeBlankIssue AddressBlankIssue BlankIssue MatrixBlankIssue ConstSumIssue SortIssue RankIssue Paragraph FileIssue TableIssue]

	def serialize(attr_ary)
		issue_obj = {}
		attr_ary.each do |attr_name|
			issue_obj[attr_name] = Marshal.load(Marshal.dump(self.send(attr_name.to_sym)))
		end
		return issue_obj
	end

	def self.create_issue(issue_type, issue_obj=nil)
		issue = Object::const_get(ISSUE_TYPE[issue_type]).new
		issue.update_issue(issue_obj) if !issue_obj.nil?
		return issue
	end

	def update_issue(attr_name_ary, issue_obj)
		attr_name_ary.each do |attr_name|
			self.send("#{attr_name}=".to_sym, Marshal.load(Marshal.dump(issue_obj[attr_name])))
		end	
	end

	def remove_hidden_items(items)
	end

	def estimate_answer_time
	end
end
