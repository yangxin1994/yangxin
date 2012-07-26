# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
OopsData::Application.initialize!

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8
CAPTCHA_SALT = 'f2413baa93a31bccfe8fdc2d604be0813775f724'
