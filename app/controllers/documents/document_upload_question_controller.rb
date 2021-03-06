module Documents
  class DocumentUploadQuestionController < Questions::QuestionsController
    layout "document_upload"

    delegate :document_type, to: :class

    def section_title
      "Documents"
    end

    def edit
      @documents = current_intake.documents.of_type(document_type)
      @form = form_class.new(document_type, current_intake, form_params)
    end

    def update
      @form = form_class.new(document_type, current_intake, form_params)
      if @form.valid?
        form_saved = @form.save
        after_update_success
      end

      redirect_to action: :edit
    end

    private

    def form_name
      "document_type_upload_form"
    end

    def self.form_class
      DocumentTypeUploadForm
    end

    def self.document_type
      DocumentNavigation.document_type(self)
    end

    def next_path(params = {})
      next_step = form_navigation.next
      document_path(next_step.to_param, params) if next_step
    end

    def current_path(params = {})
      document_path(self.class.to_param, params)
    end

    def form_navigation
      @form_navigation ||= DocumentNavigation.new(self)
    end
  end
end
