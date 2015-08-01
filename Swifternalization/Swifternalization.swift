//
//  Swifternalization.swift
//  Swifternalization
//
//  Created by Tomasz Szulc on 27/06/15.
//  Copyright (c) 2015 Tomasz Szulc. All rights reserved.
//

import Foundation

/// Handy typealias that can be used instead of longer `Swifternalization`
public typealias I18n = Swifternalization

/**
This is the main class of Swifternalization library. It exposes methods
that can be used to get localized strings.

It uses expressions.json and base.json, en.json, pl.json and so on to work.
expressions.json file contains shared expressions that are used by other 
files with translations.

Internal classes of the Swifternalization contains logic that is responsible
for detecting which value should be used for the given key and value.

Before you can get any localized value you have to configure the Swifternalization 
first. Call `configure:` method first and then you can use other methods.
*/
final public class Swifternalization {
    /**
    Shared instance of Swifternalization used internally.
    */
    private static let sharedInstance = Swifternalization()
    
    /**
    Array of translations that contain expressions and localized values.
    */
    private var translations = [Translation]()
    
    // MARK: Public Methods
    
    /**
    Call the method to configure Swifternalization.
    
    :param: bundle A bundle when expressions.json and other files are located.
    */
    public class func configure(bundle: NSBundle = NSBundle.mainBundle()) {
        sharedInstance.load(bundle: bundle)
    }
    
    /**
    Get localized value for a key.
    
    :param: key A key.
    :param: fittingWidth A max width that value should fit to. If there is no 
        value specified the full-length localized string is returned. If a
        passed fitting width is greater than highest available then a value for 
        highest available width is returned.
    :param: defaultValue A default value that is returned when there is no 
        localized value for passed `key`.
    :param: comment A comment about the key and localized value. Just for 
        developer use for describing key-value pair.
    :returns: localized string if found, otherwise `defaultValue` is returned if 
        specified or `key` if `defaultValue` is not specified.
    */
    public class func localizedString(key: String, fittingWidth: Int? = nil, defaultValue: String? = nil, comment: String? = nil) -> String {
        return localizedString(key, stringValue: key, fittingWidth: fittingWidth, defaultValue: defaultValue, comment: comment)
    }
    
    
    /**
    Get localized value for a key and string value.
    
    :param: key A key.
    :param: stringValue A value that is matched by expressions.
    :param: fittingWidth A max width that value should fit to. If there is no
        value specified the full-length localized string is returned. If a
        passed fitting width is greater than highest available then a value for
        highest available width is returned.
    :param: defaultValue A default value that is returned when there is no
        localized value for passed `key`.
    :param: comment A comment about the key and localized value. Just for
        developer use for describing key-value pair.
    :returns: localized string if found, otherwise `defaultValue` is returned if
        specified or `key` if `defaultValue` is not specified.
    */
    public class func localizedString(key: String, stringValue: String, fittingWidth: Int? = nil, defaultValue: String? = nil, comment: String? = nil) -> String {
        /**
        Filter translations and get only these that match passed `key`.
        In ideal case when all is correctly filled by a developer it should be 
        at most only one key so we're getting just first found key.
        */
        let filteredTranslations = sharedInstance.translations.filter({$0.key == key})
        if let translation = filteredTranslations.first {
            /**
            If there is translation for the `key` it should validate passed 
            `stringValue`and `fittingWidth`. Translation returns localized 
            string (that matches `fittingWidth` if specified or nil.
            If `fittingWidth` is not specified then full length localized string 
            is returned if translation matches the validated `stringValue`.
            */
            if let localizedValue = translation.validate(stringValue, fittingWidth: fittingWidth) {
                return localizedValue
            }
        }
        
        /**
        If there is not translation that validated `stringValue` successfully 
        then return `defaultValue` if not nil or the `key`.
        */
        return (defaultValue != nil) ? defaultValue! : key
    }
    
    /**
    Get localized value for a key and string value.
    
    :param: key A key.
    :param: intValue A value that is matched by expressions.
    :param: fittingWidth A max width that value should fit to. If there is no
        value specified the full-length localized string is returned. If a
        passed fitting width is greater than highest available then a value for
        highest available width is returned.
    :param: defaultValue A default value that is returned when there is no
        localized value for passed `key`.
    :param: comment A comment about the key and localized value. Just for
        developer use for describing key-value pair.
    :returns: localized string if found, otherwise `defaultValue` is returned if
        specified or `key` if `defaultValue` is not specified.
    */
    public class func localizedString(key: String, intValue: Int, fittingWidth: Int? = nil, defaultValue: String? = nil, comment: String? = nil) -> String {
        return localizedString(key, stringValue: "\(intValue)", fittingWidth: fittingWidth, defaultValue: defaultValue, comment: comment)
    }
    
    
    // MARK: Private Methods
    
    /**
    Loads expressions and translations from expression.json and translation 
    json files.
    
    :param: bundle A bundle when files are located.
    */
    private func load(bundle: NSBundle = NSBundle.mainBundle()) {
        // Set base and prefered languages.
        let base = "base"
        let language = getPreferredLanguage(bundle)
        
        /*
        Load base and prefered language expressions from expressions.json,
        convert them into SharedExpression objects and process them and return 
        array only of unique expressions. `SharedExpressionsProcessor` do its 
        own things inside like check if expression is unique or overriding base 
        expressions by prefered language ones if there is such expression.
        */
        let baseExpressions = SharedExpressionsLoader.loadExpressions(JSONFileLoader.loadExpressions(base, bundle: bundle))
        let languageExpressions = SharedExpressionsLoader.loadExpressions(JSONFileLoader.loadExpressions(language, bundle: bundle))
        let expressions = SharedExpressionsProcessor.processSharedExpression(language, preferedLanguageExpressions: languageExpressions, baseLanguageExpressions: baseExpressions)
        
        /*
        Load base and prefered language translations from proper language files 
        specified by `language` constant. Convert them into arrays of 
        `LoadedTranslation`s and then process and convert into `Translation` 
        objects using `LoadedTranslationsProcessor`.
        */
        let baseTranslations = TranslationsLoader.loadTranslations(JSONFileLoader.loadTranslations(base, bundle: bundle))
        let languageTranslations = TranslationsLoader.loadTranslations(JSONFileLoader.loadTranslations(language, bundle: bundle))
        
        // Store processed translations in `translations` variable for future use.
        translations = LoadedTranslationsProcessor.processTranslations(baseTranslations, preferedLanguageTranslations: languageTranslations, sharedExpressions: expressions)
    }
    
    /** 
    Gets preferred language of user's device
    */
    private func getPreferredLanguage(bundle: NSBundle) -> CountryCode {
        // Get preferred language, the one which is set on user's device
        return bundle.preferredLocalizations.first as! CountryCode
    }
}
