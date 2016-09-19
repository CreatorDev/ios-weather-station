/*
 * <b>Copyright (c) 2016, Imagination Technologies Limited and/or its affiliated group companies
 *  and/or licensors. </b>
 *
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without modification, are permitted
 *  provided that the following conditions are met:
 *
 *  1. Redistributions of source code must retain the above copyright notice, this list of conditions
 *      and the following disclaimer.
 *
 *  2. Redistributions in binary form must reproduce the above copyright notice, this list of
 *      conditions and the following disclaimer in the documentation and/or other materials provided
 *      with the distribution.
 *
 *  3. Neither the name of the copyright holder nor the names of its contributors may be used to
 *      endorse or promote products derived from this software without specific prior written
 *      permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 *  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 *  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 *  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 *  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 *  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 *  WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#import "WeatherEditGroupsTableViewController.h"
#import "WeatherGroupTableViewCell.h"

@interface WeatherEditGroupsTableViewController ()
@property (nonatomic, strong, nonnull) AppData *appData;
@property(nonatomic, strong, nonnull) NSMutableArray<SensorsGroup *> *groups;
@end

@implementation WeatherEditGroupsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.groups = [self.appData.groupsForEdit mutableCopy];
    [self.tableView setEditing:YES];
    [self.tableView reloadData];
}

#pragma mark - IBAction

- (IBAction)addAction:(UIBarButtonItem *)sender {
    SensorsGroup *group = [[SensorsGroup alloc] initWithGroupName:@""];
    
    __block UITextField *textField = nil;
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Enter group name"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull tField) {
        tField.text = group.name;
        textField = tField;
    }];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        group.name = textField.text;
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:self.groups.count inSection:0];
        [self.groups addObject:group];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }];
    [alert addAction:defaultAction];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)doneAction:(UIBarButtonItem *)sender {
    [self.appData setNewGroups:self.groups];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)tapGestureAction:(UITapGestureRecognizer *)sender {
    CGPoint location = [sender locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    SensorsGroup *group = self.groups[indexPath.row];
    
    __block UITextField *textField = nil;
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Change name"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull tField) {
        tField.text = group.name;
        textField = tField;
    }];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        group.name = textField.text;
        WeatherGroupTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        cell.groupNameLabel.text = textField.text;
    }];
    [alert addAction:defaultAction];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.groups.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WeatherGroupTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"WeatherGroupCell" forIndexPath:indexPath];
    cell.groupNameLabel.text = self.groups[indexPath.row].name;
    if (cell.gestureRecognizers.count == 0) {
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction:)];
        [cell.contentView addGestureRecognizer:tapGestureRecognizer];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        SensorsGroup *group = self.groups[indexPath.row];
        [self.groups removeObject:group];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    SensorsGroup *movedGroup = self.groups[fromIndexPath.row];
    [self.groups removeObject:movedGroup];
    [self.groups insertObject:movedGroup atIndex:toIndexPath.row];
}

@end
