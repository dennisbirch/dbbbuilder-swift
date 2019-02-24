//
//  DBBDatePickerView.swift
//  DBBBuilder-Swift
//
//  Created by Dennis Birch on 6/24/15.
//  Copyright (c) 2015 Dennis Birch. All rights reserved.
//

import UIKit

protocol DatePickerViewDelegate {
    func valueChanged(newDate: Date, pickerView:DBBDatePickerView)
    func dismissedDatePickerView(pickerView: DBBDatePickerView)
}

class DBBDatePickerView: UIView
{
    var delegate: DatePickerViewDelegate?
	var datePicker: UIDatePicker
    
    required init(coder aDecoder: NSCoder) {
		datePicker = UIDatePicker()

		super.init(coder: aDecoder)!
    }
    
	init(date: Date?, section: Int, showTime: Bool, superView: UIView) {
        let frame = CGRect(x: 0, y: 0, width: superView.bounds.width, height: 162.0)
        datePicker = UIDatePicker()

		super.init(frame: frame)

		datePicker.frame = frame
		
		datePicker.datePickerMode = (showTime) ? .dateAndTime : .date

		backgroundColor = UIColor.lightGray
		
		let displayDate: Date?
        if date == nil {
            displayDate = Date()
        } else {
            displayDate = date
        }
        
        guard let newDate = displayDate else {
            return
        }
        
        datePicker.date = newDate
        datePicker.tag = section
        datePicker.addTarget(self, action: #selector(datePickerValueChanged), for: UIControl.Event.valueChanged)
        addSubview(datePicker)
        
        let closeButton = UIButton(type: .system) as UIButton
        closeButton.setTitle("Done", for: .normal)
        closeButton.frame = CGRect(x: bounds.width - 60.0, y: 0, width: 60.0, height: 32.0)
        closeButton.addTarget(self, action: #selector(closeDatePickerView), for: .touchUpInside)
        addSubview(closeButton)
    }
    

	@objc func datePickerValueChanged(datePicker: UIDatePicker) {
        delegate?.valueChanged(newDate: datePicker.date, pickerView: self)
	}
	
	@objc func closeDatePickerView() {
		// make sure whatever date picker is set to is sent to delegate, 
		// even if no date was selected
        delegate?.valueChanged(newDate: datePicker.date, pickerView: self)
        delegate?.dismissedDatePickerView(pickerView: self)
	}
}
