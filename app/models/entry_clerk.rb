class EntryClerk < SystemUser

	has_and_belongs_to_many :managable_surveys, class_name: "Survey"
end