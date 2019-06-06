//
//  DestinationListViewControllerTests.swift
//  RouteAppTests
//
//  Created by Mohit Kumar on 5/26/19.
//  Copyright © 2019 Mohit Kumar. All rights reserved.
//

import Foundation
import Nimble
import Quick

@testable import RouteApp

class DestinationListViewControllerTests: QuickSpec {
    var destinationListVC: DestinationListViewController!
    
    override func spec() {
        describe("DestinationListViewController") {
            context("when view is loaded") {
                beforeEach {
                    self.destinationListVC = DestinationListViewController.stub()
                }
                                
                context("and when setupUI is called") {
                    beforeEach {
                        self.destinationListVC.setupUI()
                    }
                    
                    it("should add tableview in view") {
                        expect(self.destinationListVC.tableView).notTo(beNil())
                    }
                }

                context("and when making api call for destination list and server return valid list") {
                    beforeEach {
                        let networkClient = HTTPClientMock()
                        networkClient.jsonData = JSONHelper.jsonFileToData(jsonName: "destination")
                        networkClient.nextError = nil
                        self.destinationListVC.destinationListViewModel.fetchDestinations(networkClient: networkClient)
                    }
                    
                    it("should render data in tableview") {
                        expect(self.destinationListVC.tableView.numberOfRows(inSection: 0) == self.destinationListVC.destinationListViewModel.numberOfRows()).toEventually(beTrue(), timeout: 10)
                    }
                    
                    it("should display loader at bottom") {
                        expect(self.destinationListVC.tableView(self.destinationListVC.tableView, cellForRowAt: IndexPath(row: self.destinationListVC.destinationListViewModel.numberOfRows() - 1, section: 0)).isKind(of: LoaderCell.self)).toEventually(beTrue(), timeout: 10)
                    }
                    context("and when network not available") {
                        beforeEach {
                            let reachabilityMock = ReachabilityManagerMock()
                            reachabilityMock.isReachable = false
                            self.destinationListVC = DestinationListViewController.stub(reachabilityManager: reachabilityMock)
                            self.destinationListVC.destinationListViewModel.destinationList = []
                            self.destinationListVC.destinationListViewModel.offset = 0
                            let networkClient = HTTPClientMock()
                            networkClient.jsonData = JSONHelper.jsonFileToData(jsonName: "destination")
                            networkClient.nextError = nil
                            self.destinationListVC.destinationListViewModel.fetchDestinations(networkClient: networkClient)
                        }
                        
                        it("should load data from cache") {
                            expect(self.destinationListVC.tableView.numberOfRows(inSection: 0) == self.destinationListVC.destinationListViewModel.numberOfRows()).toEventually(beTrue(), timeout: 10)
                        }
                    }
                    
                    context("and when table scroll to bottom and will displaycell method called") {
                        beforeEach {
                            self.destinationListVC.destinationListViewModel.offset = 0
                            self.destinationListVC.tableView.delegate!.tableView!(self.destinationListVC.tableView, willDisplay: LocationCell(), forRowAt: IndexPath(row: self.destinationListVC.destinationListViewModel.numberOfRows() - 1, section: 0))
                        }
                        
                        it("should update offset value") {
                            expect(self.destinationListVC.destinationListViewModel.offset == self.destinationListVC.destinationListViewModel.destinationList.count).to(beTrue())
                        }
                    }

                    context("and when tapped on any address") {
                        beforeEach {
                            self.destinationListVC.tableView!.delegate?.tableView!(self.destinationListVC.tableView, didSelectRowAt: IndexPath (row: 1, section: 0))
                        }
                        
                        it("should open map screen with selected location parameter") {
                            expect(self.destinationListVC.navigationController?.topViewController!.isKind(of: MapViewController.self)).toEventually(beTrue(), timeout: 10)
                            
                            expect((self.destinationListVC.navigationController!.topViewController! as! MapViewController).viewModel.selectedLocation!.description == self.destinationListVC.destinationListViewModel.getDestination(index: 1).description).to(beTrue())
                        }
                    }
                }
                
                context("and when making api call for destination list and server gives error and no cache found") {
                    beforeEach {
                        DBManager.sharedInstance.cleanCache()
                        let networkClient = HTTPClientMock()
                        networkClient.jsonData = nil
                        networkClient.nextError = NSError(domain: "testError", code: 1, userInfo: nil)
                        self.destinationListVC.destinationListViewModel.fetchDestinations(networkClient: networkClient)
                    }
                    
                    it("should display error alert") {
                        expect(self.destinationListVC.presentedViewController?.isKind(of: UIAlertController.self)).toEventually(beTrue(), timeout: 10)
                    }
                }
            }
        }
    }
}
