# frozen_string_literal: true
module Hyku
  module API
    module V1
      class FeaturedWorksController < BaseController
        def create
          # TODO: Add guard against work not existing
          @featured_work = FeaturedWork.new(work_id: params[:id], order: params[:order])

          respond_to do |format|
            if @featured_work.save
              format.json { render json: { code: 201, status: :created } }
            else
              format.json { render json: @featured_work.errors, code: 422, status: :unprocessable_entity }
            end
          end
        end

        def destroy
          FeaturedWork.find_by(work_id: params[:id])&.destroy

          respond_to do |format|
            format.json { head :no_content }
          end
        end
      end
    end
  end
end
