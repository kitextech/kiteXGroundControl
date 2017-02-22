//
//  LocalPositionViewController.swift
//  kiteXGroundControl
//
//  Created by Andreas Okholm on 22/02/2017.
//  Copyright © 2017 Andreas Okholm. All rights reserved.
//

import Cocoa
import Charts
import Mavlink

class LocalPositionViewController: NSViewController {
    
    
    @IBOutlet weak var lineChartView: LineChartView!
    
    let eventManager = EventManager.shared
    var events = [mavlink_local_position_ned_t]()
    
    
    
    override open func viewDidLoad()
    {
        super.viewDidLoad()
        
        eventManager.NEDObserver = self
        
        
        // Do any additional setup after loading the view.
        let ys1 = Array(1..<10).map { x in return sin(Double(x) / 2.0 / 3.141 * 1.5) }
        let ys2 = Array(1..<10).map { x in return cos(Double(x) / 2.0 / 3.141) }
        
        let yse1 = ys1.enumerated().map { x, y in return ChartDataEntry(x: Double(x), y: y) }
        let yse2 = ys2.enumerated().map { x, y in return ChartDataEntry(x: Double(x), y: y) }
        
        let data = LineChartData()
        let ds1 = LineChartDataSet(values: yse1, label: "Hello")
        ds1.colors = [NSUIColor.red]
        data.addDataSet(ds1)
        
        let ds2 = LineChartDataSet(values: yse2, label: "World")
        ds2.colors = [NSUIColor.blue]
        data.addDataSet(ds2)
        self.lineChartView.data = data
        
        self.lineChartView.gridBackgroundColor = NSUIColor.white
        
        self.lineChartView.chartDescription?.text = "Local Position NED"
    }
    
    override open func viewWillAppear()
    {
        self.lineChartView.animate(xAxisDuration: 0.0, yAxisDuration: 1.0)
    }
    
    
    func plot() {
        
        let datasetValues = events.map { event in return ChartDataEntry(x: Double(event.x), y: Double(event.y)) }
        
        let data = LineChartData()
        let ds1 = LineChartDataSet(values: datasetValues, label: "Poition")
        ds1.colors = [NSUIColor.red]
        data.addDataSet(ds1)
        
        self.lineChartView.data = data
    }

}

extension LocalPositionViewController: LocalPositionNEDObserver {
    
    func newPosition(event: mavlink_local_position_ned_t) {
        events.append(event)
        plot()
    }
}
