class ExportResultsController < ApplicationController
#FIXME 下边的作废
	def set_spss_export_process
		result = ExportResult.find_by_result_key(parmas[:result_key])
		result.export_process[:spss_convert] = parmas[:convert_process].to_i

		render_json { result.save }
	end

	def set_excel_export_process
		result = ExportResult.find_by_result_key(parmas[:result_key])
		result.export_process[:excel_convert] = parmas[:convert_process].to_i

		render_json { result.save }
	end

end