#!/bin/env ruby
# encoding: utf-8
class RoleTrackersController < ApplicationController
  unloadable


  def edit
  end

  def index
    @role=Role.find(params[:role_id]) if params[:role_id] && User.current.admin?
  end

  def reload
    if User.current.admin?
      @role=Role.find(params[:role_id])
      RoleTrackers.delete_all("role_id = #{params[:role_id]}")
      params[:tracker].each do |id|
        RoleTrackers.create({role_id: params[:role_id], tracker_id: id}, {:without_protection => true})
      end
      redirect_to role_trackers_path+"?role_id=#{params[:role_id]}"
    end
  end

end
