date_formats = {
    default: '%d-%m-%Y' # 13-Jan-2014
}

Time::DATE_FORMATS.merge! date_formats
Date::DATE_FORMATS.merge! date_formats
DateTime::DATE_FORMATS.merge! date_formats

Rails.logger.debug(DateTime::DATE_FORMATS)