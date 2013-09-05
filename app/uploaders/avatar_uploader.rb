# encoding: utf-8

class AvatarUploader < CarrierWave::Uploader::Base
  CarrierWave::SanitizedFile.sanitize_regexp = /[^[:word:]\.\-\+]/
  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  include CarrierWave::MiniMagick

  # Include the Sprockets helpers for Rails 3.1+ asset pipeline compatibility:
  # include Sprockets::Helpers::RailsHelper
  # include Sprockets::Helpers::IsolatedHelper

  # Choose what kind of storage to use for this uploader:
  storage :file
  # storage :fog

  # MiniMagick.processor = :gm

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/avatar/"
  end

  def default_url
    "/assets/avatar/" + [version_name, "default.png"].compact.join('_')
  end

  def filename
    @name ||= "#{Digest::MD5.hexdigest(model.uid.to_s)}.png"
  end

  # version :thumb do 
  #   process :lazy_resize_300
  # end

  # version :crop, :from_version => :thumb do 
  #   process :cropper
  # end

  # version :normal, :from_version => :crop do 
  #   process :force_resize_104x104!
  # end

  version :thumb do 
    process :lazy_resize_300
    process :cropper
    process :force_resize_104x104!
    process :convert => 'png'
  end

  version :small, :from_version => :thumb do 
    process :force_resize_36x36!
  end

  version :mini, :from_version => :thumb do 
    process :force_resize_20x20!
  end

  def lazy_resize_300
    manipulate! do |img| 
      img.resize "300x300^" if img[:width].to_i < 300 && img[:height].to_i < 300
      img.resize "300x300>"
      img
    end
  end

  def force_resize_104x104!
    manipulate! do |img| 
      img.resize "104x104!"
      img
    end
  end

  def force_resize_36x36!
    manipulate! do |img| 
      img.resize "36x36!"
      img
    end
  end

  def force_resize_20x20!
    manipulate! do |img| 
      img.resize "20x20!"
      img
    end
  end

  def cropper
    if model.crop_x.present?
      manipulate! do |img|      
        x = model.crop_x
        y = model.crop_y
        w = model.crop_w
        h = model.crop_h

        size = w << 'x' << h
        offset = '+' << x << '+' << y

        img.crop("#{size}#{offset}") # Doesn't return an image...
        img # ...so you'll neet to call it yourself
      end 
    end
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  # version :thumb do
  #   process :scale => [50, 50]
  # end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  # def extension_white_list
  #   %w(jpg jpeg gif png)
  # end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end

end
