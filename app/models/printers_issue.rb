#!/bin/env ruby
# encoding: utf-8
class PrintersIssue < ActiveRecord::Base
  unloadable

  include ActiveModel::Validations
  validates :printer_id, :issue_id, presence: true
  validates :printer_id, uniqueness: { scope: [:issue_id],
                                     message: "должен быть только один принтер на заявку" }
  validate { |pi|
    errors.add(:base, 'Количество принятых картриджей не может быть больше заявленных') if pi.crtr_plan && pi.crtr_real && pi.crtr_plan > pi.crtr_real
  }
  validate { |pi|
    errors.add(:base, 'Количество отправленных картриджей на заправку не может быть больше принятых') if pi.crtr_real && pi.crtr_send && pi.crtr_real > pi.crtr_send
  }
  validate { |pi| errors.add(:base, 'Количество принятых картриджей не может быть больше заявленных') if pi.crtr_send && pi.crtr_filled && pi.crtr_restored && pi.crtr_killed && pi.crtr_send != (pi.crtr_filled + pi.crtr_restored + pi.crtr_killed)}

  before_save :before_save

  belongs_to :printer
  belongs_to :issue

  def name
    printer.name
  end

  def printer_name
    printer.name
  end

  def brand
    printer.brand
  end

  def inventory
    printer.inventory
  end

  def serial
    printer.serial
  end

  def oa_name
    issue.oa_name
  end

  def cartridge_category
    printer.printer_category.cartridge
  end

  def where_category (category='')
    self.joins(printer: :printer_category).where(printer_category: {cartridge: category})
  end

private
  def before_save

  end
end
