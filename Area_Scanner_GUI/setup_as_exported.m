classdef setup_as_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        SetupUIFigure                        matlab.ui.Figure
        GridLayout                           matlab.ui.container.GridLayout
        LeftPanel                            matlab.ui.container.Panel

        % ── Area Selection panel ──────────────────────────────────────────
        AreaselectionPanel                   matlab.ui.container.Panel
        AreaRect1Header                      matlab.ui.control.Label
        AreaRect2Header                      matlab.ui.control.Label
        AreaXLeftLabel                       matlab.ui.control.Label
        AreaXRightLabel                      matlab.ui.control.Label
        AreaYNearLabel                       matlab.ui.control.Label
        AreaYFarLabel                        matlab.ui.control.Label
        Rect1XLeft                           matlab.ui.control.NumericEditField
        Rect1XRight                          matlab.ui.control.NumericEditField
        Rect1YNear                           matlab.ui.control.NumericEditField
        Rect1YFar                            matlab.ui.control.NumericEditField
        Rect2XLeft                           matlab.ui.control.NumericEditField
        Rect2XRight                          matlab.ui.control.NumericEditField
        Rect2YNear                           matlab.ui.control.NumericEditField
        Rect2YFar                            matlab.ui.control.NumericEditField

        % ── Visualizer Options ────────────────────────────────────────────
        VisualizerOptionsButtonGroup         matlab.ui.container.ButtonGroup
        ProjTime                             matlab.ui.control.NumericEditField
        ProjectionTimesecLabel               matlab.ui.control.Label
        WarnEnd                              matlab.ui.control.NumericEditField
        RangeWarningZoneEndmLabel            matlab.ui.control.Label
        WarnStart                            matlab.ui.control.NumericEditField
        RangeWarningZoneStartmLabel          matlab.ui.control.Label
        EnableZones                          matlab.ui.control.CheckBox
        CriticalEnd                          matlab.ui.control.NumericEditField
        RangeCriticalZoneEndmLabel           matlab.ui.control.Label
        CriticalStart                        matlab.ui.control.NumericEditField
        RangeCriticalZoneStartmLabel         matlab.ui.control.Label

        % ── Sensor Information ────────────────────────────────────────────
        SensorInformationButtonGroup         matlab.ui.container.ButtonGroup
        ElevationTilt                        matlab.ui.control.NumericEditField
        SensorElevationTiltdegEditFieldLabel matlab.ui.control.Label
        MountingHeight                       matlab.ui.control.NumericEditField
        SensorMountingHeightmEditFieldLabel  matlab.ui.control.Label

        % ── Record Data ───────────────────────────────────────────────────
        RecordDataPanel                      matlab.ui.container.Panel
        AppendtimedateCheckBox               matlab.ui.control.CheckBox
        SaveName                             matlab.ui.control.EditField
        FileNameLabel                        matlab.ui.control.Label
        EnableRecord                         matlab.ui.control.CheckBox
        LogButton                            matlab.ui.control.Button
        SavePath                             matlab.ui.control.EditField
        SaveDirectoryLabel                   matlab.ui.control.Label

        % ── CFG File ─────────────────────────────────────────────────────
        SelectCFGFilePanel                   matlab.ui.container.Panel
        CfgButton                            matlab.ui.control.Button
        CfgPath                              matlab.ui.control.EditField
        CFGFileLabel                         matlab.ui.control.Label

        % ── Visualizer Mode ───────────────────────────────────────────────
        VisualizerModeButtonGroup            matlab.ui.container.ButtonGroup
        DatPanel                             matlab.ui.container.Panel
        DatPath                              matlab.ui.control.EditField
        DataFileLabel                        matlab.ui.control.Label
        DatButton                            matlab.ui.control.Button
        COMPanel                             matlab.ui.container.Panel
        TestConnectionButton                 matlab.ui.control.Button
        DatPort                              matlab.ui.control.NumericEditField
        DATA_PORTLabel                       matlab.ui.control.Label
        CfgPort                              matlab.ui.control.NumericEditField
        CFG_PORTLabel                        matlab.ui.control.Label
        PlayBackButton                       matlab.ui.control.ToggleButton
        RealTimeButton                       matlab.ui.control.ToggleButton

        % ── Bottom action buttons ─────────────────────────────────────────
        CalibrationButton                    matlab.ui.control.Button
        SetupCompleteButton                  matlab.ui.control.Button

        % ── Right panel (kept for grid layout, no visible content) ────────
        RightPanel                           matlab.ui.container.Panel
    end

    properties (Access = private)
        onePanelWidth = 576;
    end

    properties (Access = public)
        mode    = 1;
        datFile = struct('name', [], 'path', []);
        cfgFile = struct('name', [], 'path', []);
        logFile = struct('name', [], 'path', []);
        offset  = struct('height', [], 'az', [], 'rot', []);
        comPort = struct('cfg', 1, 'data', 1, 'status', 0);
    end

    % ─────────────────────────────────────────────────────────────────────
    % Callbacks
    % ─────────────────────────────────────────────────────────────────────
    methods (Access = private)

        % Reflow on resize
        function updateAppLayout(app, ~)
            currentFigureWidth = app.SetupUIFigure.Position(3);
            if currentFigureWidth <= app.onePanelWidth
                app.GridLayout.RowHeight    = {700, 700};
                app.GridLayout.ColumnWidth  = {'1x'};
                app.RightPanel.Layout.Row    = 2;
                app.RightPanel.Layout.Column = 1;
            else
                app.GridLayout.RowHeight    = {'1x'};
                app.GridLayout.ColumnWidth  = {552, '1x'};
                app.RightPanel.Layout.Row    = 1;
                app.RightPanel.Layout.Column = 2;
            end
        end

        % Visualizer Mode toggle
            function VisualizerModeButtonGroupSelectionChanged(app, ~)
                if app.RealTimeButton.Value % Modo Real Time, usa ligação USB com o sensor
                    app.mode = 1;
                    app.DatPanel.Visible        = 'off';
                    app.COMPanel.Visible        = 'on';
                    app.RecordDataPanel.Visible = 'on';
                else % Modo Playback
                    app.mode = 2;
                    app.DatPanel.Visible        = 'on';
                    app.COMPanel.Visible        = 'off';
                    app.RecordDataPanel.Visible = 'off';
                end
            end

        % Browse data log file
        function DatButtonPushed(app, ~)
            [app.datFile.name, app.datFile.path] = uigetfile('*.txt', 'Select Log File');
            if ischar(app.datFile.name)
                app.DatPath.Value = [app.datFile.path app.datFile.name];
            end
            figure(app.SetupUIFigure);
        end

        % Browse CFG file
        function CfgButtonPushed(app, ~)
            [app.cfgFile.name, app.cfgFile.path] = uigetfile('*.cfg', 'Select CFG File');
            if ischar(app.cfgFile.name)
                app.CfgPath.Value = [app.cfgFile.path app.cfgFile.name];
            end
            figure(app.SetupUIFigure);
        end

        % Browse log folder
        function LogButtonPushed(app, ~)
            app.logFile.path = uigetdir('Select Folder to Save');
            if ischar(app.logFile.path)
                app.SavePath.Value = app.logFile.path;
            end
            figure(app.SetupUIFigure);
        end

        % CFG path typed manually
        function CfgPathValueChanged(app, ~)
            [app.cfgFile.path, name, ext] = fileparts(app.CfgPath.Value);
            app.cfgFile.name = [name ext];
        end

        % Data path typed manually
        function DatPathValueChanged(app, ~)
            [app.datFile.path, name, ext] = fileparts(app.DatPath.Value);
            app.datFile.name = [name ext];
        end

        % COM port changes
        function CfgPortValueChanged(app, ~)
            app.comPort.cfg = app.CfgPort.Value;
        end

        function DatPortValueChanged(app, ~)
            app.comPort.data = app.DatPort.Value;
        end

        % Test serial connection
        function TestConnectionButtonPushed(app, ~)
            hDataPort = initDataPort(app.DatPort.Value);
            hCfgPort  = initCfgPort(app.CfgPort.Value);
            if hCfgPort ~= -1 && hDataPort ~= -1
                if hDataPort.BytesAvailable
                    uialert(app.SetupUIFigure, ...
                        'Device appears to already be running. Will not be able to load a new configuration. To load a new config, press NRST on the EVM and try again.', ...
                        'Need to assert NRST');
                    app.comPort.status = -1;
                    return;
                else
                    fprintf(hCfgPort, 'version');
                    pause(0.5);
                    response = '';
                    if hCfgPort.BytesAvailable
                        for i = 1:10
                            rstr     = fgets(hCfgPort);
                            response = append(response, rstr);
                        end
                        uialert(app.SetupUIFigure, response, ...
                            'Test successful: CFG Port Opened & Data Received', 'icon', 'success');
                        app.comPort.status = 1;
                    else
                        uialert(app.SetupUIFigure, ...
                            'Port opened but no response received. Check port # and SOP mode on EVM', ...
                            'Issue with CFG Port');
                        app.comPort.status = -2;
                        fclose(hDataPort);
                        fclose(hCfgPort);
                    end
                end
            else
                app.comPort.status = -2;
                uialert(app.SetupUIFigure, ...
                    'Could not open ports. Check port # and that EVM is powered with correct SOP mode.', ...
                    'Ports not valid');
            end
        end

        % ── Calibração de Áreas ───────────────────────────────────────────
        function CalibrationButtonPushed(app, ~)
            % Process CfgPath the same way SetupComplete does
            [cPath, cName, cExt] = fileparts(app.CfgPath.Value);
            if ~isempty(cName)
                app.cfgFile.path = [cPath '\'];
                app.cfgFile.name = [cName cExt];
            end

            % Save port numbers, cfg path, and offset for calibration_plot
            cfgPortNum = app.CfgPort.Value;     %#ok<NASGU>
            datPortNum = app.DatPort.Value;      %#ok<NASGU>
            cfgFile    = app.cfgFile;            %#ok<NASGU>
            comStatus  = app.comPort.status;     %#ok<NASGU>
            offset_height = app.MountingHeight.Value; %#ok<NASGU>
            offset_el     = app.ElevationTilt.Value;  %#ok<NASGU>
            save('temp_config.mat', 'cfgPortNum', 'datPortNum', ...
                 'cfgFile', 'comStatus', 'offset_height', 'offset_el');

            % Hide setup while calibration runs
            app.SetupUIFigure.Visible = 'off';

            % Open calibration plot (blocks until "Voltar ao Setup" is clicked)
            try
                calibration_plot();
            catch ME
                uialert(app.SetupUIFigure, ...
                    ['Erro na calibração: ' ME.message], 'Erro de Calibração');
            end

            % Reload rect1/rect2 from state.mat into the UI fields
            if exist('state.mat', 'file')
                try
                    S = load('state.mat');
                    if isfield(S, 'rect1')
                        app.Rect1XLeft.Value  = S.rect1.xLeft;
                        app.Rect1XRight.Value = S.rect1.xRight;
                        app.Rect1YNear.Value  = S.rect1.yNear;
                        app.Rect1YFar.Value   = S.rect1.yFar;
                    end
                    if isfield(S, 'rect2')
                        app.Rect2XLeft.Value  = S.rect2.xLeft;
                        app.Rect2XRight.Value = S.rect2.xRight;
                        app.Rect2YNear.Value  = S.rect2.yNear;
                        app.Rect2YFar.Value   = S.rect2.yFar;
                    end
                catch
                    % Silent – user can set fields manually
                end
            end

            % Show setup again
            app.SetupUIFigure.Visible = 'on';
            figure(app.SetupUIFigure);
        end

        % ── Setup Complete ────────────────────────────────────────────────
        function SetupCompleteButtonPushed(app, ~)

            % 1. Collect file paths
            [dPath, dName, dExt] = fileparts(app.DatPath.Value);
            app.datFile.path = [dPath '\'];
            app.datFile.name = [dName dExt];

            [cPath, cName, cExt] = fileparts(app.CfgPath.Value);
            app.cfgFile.path = [cPath '\'];
            app.cfgFile.name = [cName cExt];

            app.logFile.path  = app.SavePath.Value;
            app.logFile.name  = app.SaveName.Value;
            app.offset.height = app.MountingHeight.Value;
            app.offset.el     = app.ElevationTilt.Value;
            app.comPort.cfg   = app.CfgPort.Value;
            app.comPort.data  = app.DatPort.Value;

            % 2. Build local variables for save()
            REAL_TIME_MODE = app.RealTimeButton.Value; %#ok<NASGU>
            ENABLE_RECORD  = app.EnableRecord.Value;   %#ok<NASGU>
            datFile = app.datFile; %#ok<NASGU>
            cfgFile = app.cfgFile; %#ok<NASGU>
            logFile = app.logFile; %#ok<NASGU>
            offset  = app.offset;  %#ok<NASGU>
            comPort = app.comPort; %#ok<NASGU>

            zones = struct( ...
                'enable',        app.EnableZones.Value, ...
                'criticalStart', app.CriticalStart.Value, ...
                'criticalEnd',   app.CriticalEnd.Value, ...
                'warnStart',     app.WarnStart.Value, ...
                'warnEnd',       app.WarnEnd.Value, ...
                'projTime',      app.ProjTime.Value); %#ok<NASGU>

            % 3. Build rect structs with exact field names expected by visualizer
            rect1 = struct( ...
                'xLeft',  app.Rect1XLeft.Value, ...
                'xRight', app.Rect1XRight.Value, ...
                'yNear',  app.Rect1YNear.Value, ...
                'yFar',   app.Rect1YFar.Value); %#ok<NASGU>

            rect2 = struct( ...
                'xLeft',  app.Rect2XLeft.Value, ...
                'xRight', app.Rect2XRight.Value, ...
                'yNear',  app.Rect2YNear.Value, ...
                'yFar',   app.Rect2YFar.Value); %#ok<NASGU>

            % 4. Save ALL variables the visualizer needs to disk
            save('state.mat', ...
                'REAL_TIME_MODE', 'ENABLE_RECORD', ...
                'datFile', 'cfgFile', 'logFile', 'offset', ...
                'comPort', 'zones', 'rect1', 'rect2');

            % 5. Close setup → releases uiwait in constructor
            closereq
        end

        % Enable / disable zone fields
        function EnableZonesValueChanged(app, ~)
            if app.EnableZones.Value, s = 'on'; else, s = 'off'; end
            app.CriticalStart.Enable = s;
            app.CriticalEnd.Enable   = s;
            app.WarnStart.Enable     = s;
            app.WarnEnd.Enable       = s;
            app.ProjTime.Enable      = s;
        end

    end % callbacks

    % ─────────────────────────────────────────────────────────────────────
    % Component creation
    % ─────────────────────────────────────────────────────────────────────
    methods (Access = private)

        function createComponents(app)

            % Layout constants
            Lx = 7;    % left margin
            PW = 535;  % panel width

            % ── Figure ───────────────────────────────────────────────────
            app.SetupUIFigure = uifigure('Visible', 'off');
            app.SetupUIFigure.AutoResizeChildren = 'off';
            app.SetupUIFigure.Position  = [100 100 564 700];
            app.SetupUIFigure.Name      = 'Setup';
            app.SetupUIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);
            app.SetupUIFigure.Scrollable = 'on';

            % ── Grid ─────────────────────────────────────────────────────
            app.GridLayout = uigridlayout(app.SetupUIFigure);
            app.GridLayout.ColumnWidth   = {552, '1x'};
            app.GridLayout.RowHeight     = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing    = 0;
            app.GridLayout.Padding       = [0 0 0 0];
            app.GridLayout.Scrollable    = 'on';

            % ── Left Panel ────────────────────────────────────────────────
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row    = 1;
            app.LeftPanel.Layout.Column = 1;
            app.LeftPanel.Scrollable    = 'on';

            % ═════════════════════════════════════════════════════════════
            % BOTTOM ACTION BUTTONS  (y = 12, height = 44)
            % Left half: Calibração de Áreas  |  Right half: Setup Complete
            % ═════════════════════════════════════════════════════════════
            yBtn  = 12;
            halfW = round(PW / 2) - 4;

            app.CalibrationButton = uibutton(app.LeftPanel, 'push');
            app.CalibrationButton.ButtonPushedFcn = ...
                createCallbackFcn(app, @CalibrationButtonPushed, true);
            app.CalibrationButton.Text            = '⬡   Calibração de Áreas';
            app.CalibrationButton.FontSize        = 12;
            app.CalibrationButton.FontWeight      = 'bold';
            app.CalibrationButton.BackgroundColor = [0.18 0.38 0.62];
            app.CalibrationButton.FontColor       = [1.00 1.00 1.00];
            app.CalibrationButton.Position        = [Lx, yBtn, halfW, 44];

            app.SetupCompleteButton = uibutton(app.LeftPanel, 'push');
            app.SetupCompleteButton.ButtonPushedFcn = ...
                createCallbackFcn(app, @SetupCompleteButtonPushed, true);
            app.SetupCompleteButton.Text            = '✔   Setup Complete';
            app.SetupCompleteButton.FontSize        = 12;
            app.SetupCompleteButton.FontWeight      = 'bold';
            app.SetupCompleteButton.BackgroundColor = [0.47 0.67 0.19];
            app.SetupCompleteButton.FontColor       = [1.00 1.00 1.00];
            app.SetupCompleteButton.Position        = [Lx + halfW + 8, yBtn, PW - halfW - 8, 44];

            % ═════════════════════════════════════════════════════════════
            % AREA SELECTION PANEL  (y = 62, height = 145)
            % Table layout: row-label | Rect 1 field | Rect 2 field
            % ═════════════════════════════════════════════════════════════
            app.AreaselectionPanel = uipanel(app.LeftPanel);
            app.AreaselectionPanel.Title      = 'Area Selection (manual)';
            app.AreaselectionPanel.FontWeight = 'bold';
            app.AreaselectionPanel.FontSize   = 10;
            app.AreaselectionPanel.Position   = [Lx 62 270 145];

            % Column headers
            app.AreaRect1Header = uilabel(app.AreaselectionPanel);
            app.AreaRect1Header.Position              = [95 118 75 22];
            app.AreaRect1Header.Text                  = 'Rect 1';
            app.AreaRect1Header.FontWeight            = 'bold';
            app.AreaRect1Header.HorizontalAlignment   = 'center';

            app.AreaRect2Header = uilabel(app.AreaselectionPanel);
            app.AreaRect2Header.Position              = [180 118 75 22];
            app.AreaRect2Header.Text                  = 'Rect 2';
            app.AreaRect2Header.FontWeight            = 'bold';
            app.AreaRect2Header.HorizontalAlignment   = 'center';

            % X Left row
            app.AreaXLeftLabel = uilabel(app.AreaselectionPanel);
            app.AreaXLeftLabel.Position              = [5 93 82 22];
            app.AreaXLeftLabel.Text                  = 'X Left [m]';
            app.AreaXLeftLabel.HorizontalAlignment   = 'right';

            app.Rect1XLeft = uieditfield(app.AreaselectionPanel, 'numeric');
            app.Rect1XLeft.Position            = [95 93 75 22];
            app.Rect1XLeft.HorizontalAlignment = 'center';
            app.Rect1XLeft.Tooltip             = {'Left edge X of Rectangle 1 [m]'};
            app.Rect1XLeft.Value               = -2;

            app.Rect2XLeft = uieditfield(app.AreaselectionPanel, 'numeric');
            app.Rect2XLeft.Position            = [180 93 75 22];
            app.Rect2XLeft.HorizontalAlignment = 'center';
            app.Rect2XLeft.Tooltip             = {'Left edge X of Rectangle 2 [m]'};
            app.Rect2XLeft.Value               = 0;

            % X Right row
            app.AreaXRightLabel = uilabel(app.AreaselectionPanel);
            app.AreaXRightLabel.Position              = [5 66 82 22];
            app.AreaXRightLabel.Text                  = 'X Right [m]';
            app.AreaXRightLabel.HorizontalAlignment   = 'right';

            app.Rect1XRight = uieditfield(app.AreaselectionPanel, 'numeric');
            app.Rect1XRight.Position            = [95 66 75 22];
            app.Rect1XRight.HorizontalAlignment = 'center';
            app.Rect1XRight.Tooltip             = {'Right edge X of Rectangle 1 [m]'};
            app.Rect1XRight.Value               = 0;

            app.Rect2XRight = uieditfield(app.AreaselectionPanel, 'numeric');
            app.Rect2XRight.Position            = [180 66 75 22];
            app.Rect2XRight.HorizontalAlignment = 'center';
            app.Rect2XRight.Tooltip             = {'Right edge X of Rectangle 2 [m]'};
            app.Rect2XRight.Value               = 2;

            % Y Near row
            app.AreaYNearLabel = uilabel(app.AreaselectionPanel);
            app.AreaYNearLabel.Position              = [5 39 82 22];
            app.AreaYNearLabel.Text                  = 'Y Near [m]';
            app.AreaYNearLabel.HorizontalAlignment   = 'right';

            app.Rect1YNear = uieditfield(app.AreaselectionPanel, 'numeric');
            app.Rect1YNear.Position            = [95 39 75 22];
            app.Rect1YNear.HorizontalAlignment = 'center';
            app.Rect1YNear.Tooltip             = {'Near Y edge of Rectangle 1 [m]'};
            app.Rect1YNear.Value               = 0.5;

            app.Rect2YNear = uieditfield(app.AreaselectionPanel, 'numeric');
            app.Rect2YNear.Position            = [180 39 75 22];
            app.Rect2YNear.HorizontalAlignment = 'center';
            app.Rect2YNear.Tooltip             = {'Near Y edge of Rectangle 2 [m]'};
            app.Rect2YNear.Value               = 0.5;

            % Y Far row
            app.AreaYFarLabel = uilabel(app.AreaselectionPanel);
            app.AreaYFarLabel.Position              = [5 12 82 22];
            app.AreaYFarLabel.Text                  = 'Y Far [m]';
            app.AreaYFarLabel.HorizontalAlignment   = 'right';

            app.Rect1YFar = uieditfield(app.AreaselectionPanel, 'numeric');
            app.Rect1YFar.Position            = [95 12 75 22];
            app.Rect1YFar.HorizontalAlignment = 'center';
            app.Rect1YFar.Tooltip             = {'Far Y edge of Rectangle 1 [m]'};
            app.Rect1YFar.Value               = 3;

            app.Rect2YFar = uieditfield(app.AreaselectionPanel, 'numeric');
            app.Rect2YFar.Position            = [180 12 75 22];
            app.Rect2YFar.HorizontalAlignment = 'center';
            app.Rect2YFar.Tooltip             = {'Far Y edge of Rectangle 2 [m]'};
            app.Rect2YFar.Value               = 3;

            % ═════════════════════════════════════════════════════════════
            % SENSOR INFORMATION  (y = 212, height = 94)
            % ═════════════════════════════════════════════════════════════
            app.SensorInformationButtonGroup = uibuttongroup(app.LeftPanel);
            app.SensorInformationButtonGroup.Title      = 'Sensor Information';
            app.SensorInformationButtonGroup.FontWeight = 'bold';
            app.SensorInformationButtonGroup.FontSize   = 14;
            app.SensorInformationButtonGroup.Position   = [Lx 212 265 94];

            app.SensorMountingHeightmEditFieldLabel = uilabel(app.SensorInformationButtonGroup);
            app.SensorMountingHeightmEditFieldLabel.HorizontalAlignment = 'right';
            app.SensorMountingHeightmEditFieldLabel.Position            = [11 38 158 22];
            app.SensorMountingHeightmEditFieldLabel.Text                = 'Sensor Mounting Height [m]:';

            app.MountingHeight = uieditfield(app.SensorInformationButtonGroup, 'numeric');
            app.MountingHeight.LowerLimitInclusive  = 'off';
            app.MountingHeight.Limits               = [0 Inf];
            app.MountingHeight.HorizontalAlignment  = 'center';
            app.MountingHeight.Tooltip              = {'Height of the sensor from the ground'};
            app.MountingHeight.Position             = [180 38 41 22];
            app.MountingHeight.Value                = 1;

            app.SensorElevationTiltdegEditFieldLabel = uilabel(app.SensorInformationButtonGroup);
            app.SensorElevationTiltdegEditFieldLabel.Position = [18 9 148 22];
            app.SensorElevationTiltdegEditFieldLabel.Text     = 'Sensor Elevation Tilt [deg]:';

            app.ElevationTilt = uieditfield(app.SensorInformationButtonGroup, 'numeric');
            app.ElevationTilt.Limits              = [-90 90];
            app.ElevationTilt.HorizontalAlignment = 'center';
            app.ElevationTilt.Tooltip             = {'Rotation about X-axis. + upwards, - down. Valid: -90 to 90'};
            app.ElevationTilt.Position            = [181 9 41 22];
            app.ElevationTilt.Value               = -10;

            % ═════════════════════════════════════════════════════════════
            % VISUALIZER OPTIONS  (y = 62, height = 244, right column x=285)
            % Spans same vertical range as AreaPanel + SensorInfo combined
            % ═════════════════════════════════════════════════════════════
            app.VisualizerOptionsButtonGroup = uibuttongroup(app.LeftPanel);
            app.VisualizerOptionsButtonGroup.Title      = 'Visualizer Options';
            app.VisualizerOptionsButtonGroup.FontWeight = 'bold';
            app.VisualizerOptionsButtonGroup.FontSize   = 14;
            app.VisualizerOptionsButtonGroup.Position   = [285 62 256 244];

            app.EnableZones = uicheckbox(app.VisualizerOptionsButtonGroup);
            app.EnableZones.ValueChangedFcn = createCallbackFcn(app, @EnableZonesValueChanged, true);
            app.EnableZones.Text            = 'Show zone occupancy';
            app.EnableZones.Position        = [16 196 142 22];
            app.EnableZones.Value           = true;

            app.RangeCriticalZoneStartmLabel = uilabel(app.VisualizerOptionsButtonGroup);
            app.RangeCriticalZoneStartmLabel.Position = [24 170 164 22];
            app.RangeCriticalZoneStartmLabel.Text     = 'Range Critical Zone Start [m]:';

            app.CriticalStart = uieditfield(app.VisualizerOptionsButtonGroup, 'numeric');
            app.CriticalStart.UpperLimitInclusive   = 'off';
            app.CriticalStart.Limits                = [0 Inf];
            app.CriticalStart.RoundFractionalValues = 'on';
            app.CriticalStart.HorizontalAlignment   = 'center';
            app.CriticalStart.Tooltip               = {'Radial distance for start of critical (red) zone.'};
            app.CriticalStart.Position              = [198 170 34 22];

            app.RangeCriticalZoneEndmLabel = uilabel(app.VisualizerOptionsButtonGroup);
            app.RangeCriticalZoneEndmLabel.Position = [24 146 160 22];
            app.RangeCriticalZoneEndmLabel.Text     = 'Range Critical Zone End [m]:';

            app.CriticalEnd = uieditfield(app.VisualizerOptionsButtonGroup, 'numeric');
            app.CriticalEnd.LowerLimitInclusive = 'off';
            app.CriticalEnd.Limits              = [0 Inf];
            app.CriticalEnd.HorizontalAlignment = 'center';
            app.CriticalEnd.Tooltip             = {'Radial distance for end of critical (red) zone.'};
            app.CriticalEnd.Position            = [198 146 34 22];
            app.CriticalEnd.Value               = 2;

            app.RangeWarningZoneStartmLabel = uilabel(app.VisualizerOptionsButtonGroup);
            app.RangeWarningZoneStartmLabel.Position = [24 122 171 22];
            app.RangeWarningZoneStartmLabel.Text     = 'Range Warning Zone Start [m]:';

            app.WarnStart = uieditfield(app.VisualizerOptionsButtonGroup, 'numeric');
            app.WarnStart.UpperLimitInclusive   = 'off';
            app.WarnStart.Limits                = [0 Inf];
            app.WarnStart.RoundFractionalValues = 'on';
            app.WarnStart.HorizontalAlignment   = 'center';
            app.WarnStart.Tooltip               = {'Radial distance for start of warning (yellow) zone.'};
            app.WarnStart.Position              = [198 122 34 22];
            app.WarnStart.Value                 = 2;

            app.RangeWarningZoneEndmLabel = uilabel(app.VisualizerOptionsButtonGroup);
            app.RangeWarningZoneEndmLabel.Position = [24 98 167 22];
            app.RangeWarningZoneEndmLabel.Text     = 'Range Warning Zone End [m]:';

            app.WarnEnd = uieditfield(app.VisualizerOptionsButtonGroup, 'numeric');
            app.WarnEnd.LowerLimitInclusive = 'off';
            app.WarnEnd.Limits              = [0 Inf];
            app.WarnEnd.HorizontalAlignment = 'center';
            app.WarnEnd.Tooltip             = {'Radial distance for end of warning (yellow) zone.'};
            app.WarnEnd.Position            = [198 98 34 22];
            app.WarnEnd.Value               = 4;

            app.ProjectionTimesecLabel = uilabel(app.VisualizerOptionsButtonGroup);
            app.ProjectionTimesecLabel.Position = [24 66 120 22];
            app.ProjectionTimesecLabel.Text     = 'Projection Time [sec]:';

            app.ProjTime = uieditfield(app.VisualizerOptionsButtonGroup, 'numeric');
            app.ProjTime.LowerLimitInclusive = 'off';
            app.ProjTime.Limits              = [0 Inf];
            app.ProjTime.HorizontalAlignment = 'center';
            app.ProjTime.Tooltip             = {'Time window for zone projection.'};
            app.ProjTime.Position            = [198 66 34 22];
            app.ProjTime.Value               = 2;

            % ═════════════════════════════════════════════════════════════
            % RECORD DATA  (y = 311, height = 103)
            % ═════════════════════════════════════════════════════════════
            app.RecordDataPanel = uipanel(app.LeftPanel);
            app.RecordDataPanel.Title      = 'Record Data';
            app.RecordDataPanel.FontWeight = 'bold';
            app.RecordDataPanel.FontSize   = 14;
            app.RecordDataPanel.Position   = [Lx 311 PW 103];

            app.SaveDirectoryLabel = uilabel(app.RecordDataPanel);
            app.SaveDirectoryLabel.FontWeight = 'bold';
            app.SaveDirectoryLabel.Position   = [18 32 90 22];
            app.SaveDirectoryLabel.Text       = 'Save Directory';

            app.SavePath = uieditfield(app.RecordDataPanel, 'text');
            app.SavePath.FontSize = 10;
            app.SavePath.Tooltip  = {'Browse or leave blank for current directory.'};
            app.SavePath.Position = [113 32 302 22];

            app.LogButton = uibutton(app.RecordDataPanel, 'push');
            app.LogButton.ButtonPushedFcn = createCallbackFcn(app, @LogButtonPushed, true);
            app.LogButton.Icon     = 'foldericon.png';
            app.LogButton.Position = [420 32 98 22];
            app.LogButton.Text     = 'Browse';

            app.EnableRecord = uicheckbox(app.RecordDataPanel);
            app.EnableRecord.Text     = 'Enable recording. UART stream will be saved to file.';
            app.EnableRecord.Position = [15 53 303 22];
            app.EnableRecord.Value    = true;

            app.FileNameLabel = uilabel(app.RecordDataPanel);
            app.FileNameLabel.FontWeight = 'bold';
            app.FileNameLabel.Position   = [19 5 62 22];
            app.FileNameLabel.Text       = 'File Name';

            app.SaveName = uieditfield(app.RecordDataPanel, 'text');
            app.SaveName.FontSize = 10;
            app.SaveName.Tooltip  = {'Log file name.'};
            app.SaveName.Position = [114 5 270 22];
            app.SaveName.Value    = 'as_demo_uart_stream.txt';

            app.AppendtimedateCheckBox = uicheckbox(app.RecordDataPanel);
            app.AppendtimedateCheckBox.Enable   = 'off';
            app.AppendtimedateCheckBox.Visible  = 'off';
            app.AppendtimedateCheckBox.Text     = 'Append time & date';
            app.AppendtimedateCheckBox.Position = [391 5 127 22];
            app.AppendtimedateCheckBox.Value    = true;

            % ═════════════════════════════════════════════════════════════
            % SELECT CFG FILE  (y = 419, height = 59)
            % ═════════════════════════════════════════════════════════════
            app.SelectCFGFilePanel = uipanel(app.LeftPanel);
            app.SelectCFGFilePanel.Title      = 'Select CFG File';
            app.SelectCFGFilePanel.FontWeight = 'bold';
            app.SelectCFGFilePanel.FontSize   = 14;
            app.SelectCFGFilePanel.Position   = [Lx 419 PW 59];

            app.CFGFileLabel = uilabel(app.SelectCFGFilePanel);
            app.CFGFileLabel.FontWeight = 'bold';
            app.CFGFileLabel.Position   = [19 7 55 22];
            app.CFGFileLabel.Text       = 'CFG File';

            app.CfgPath = uieditfield(app.SelectCFGFilePanel, 'text');
            app.CfgPath.ValueChangedFcn = createCallbackFcn(app, @CfgPathValueChanged, true);
            app.CfgPath.FontSize        = 10;
            app.CfgPath.Tooltip         = {'Enter full path or use Browse.'};
            app.CfgPath.Position        = [82 8 333 21];

            app.CfgButton = uibutton(app.SelectCFGFilePanel, 'push');
            app.CfgButton.ButtonPushedFcn = createCallbackFcn(app, @CfgButtonPushed, true);
            app.CfgButton.Icon     = 'folder_file_icon.png';
            app.CfgButton.Position = [420 7 100 22];
            app.CfgButton.Text     = 'Browse';

            % ═════════════════════════════════════════════════════════════
            % VISUALIZER MODE  (y = 483, height = 173)
            % ═════════════════════════════════════════════════════════════
            app.VisualizerModeButtonGroup = uibuttongroup(app.LeftPanel);
            app.VisualizerModeButtonGroup.SelectionChangedFcn = ...
                createCallbackFcn(app, @VisualizerModeButtonGroupSelectionChanged, true);
            app.VisualizerModeButtonGroup.Title      = 'Visualizer Mode';
            app.VisualizerModeButtonGroup.FontWeight = 'bold';
            app.VisualizerModeButtonGroup.FontSize   = 14;
            app.VisualizerModeButtonGroup.Position   = [8 483 PW 173];

            app.RealTimeButton = uitogglebutton(app.VisualizerModeButtonGroup);
            app.RealTimeButton.Text     = 'Real Time';
            app.RealTimeButton.Position = [11 118 240 22];
            app.RealTimeButton.Value    = true;

            app.PlayBackButton = uitogglebutton(app.VisualizerModeButtonGroup);
            app.PlayBackButton.Text     = 'Play Back';
            app.PlayBackButton.Position = [278 118 240 22];

            % COM panel (Real Time)
            app.COMPanel = uipanel(app.VisualizerModeButtonGroup);
            app.COMPanel.Title    = 'Set COM port for real time';
            app.COMPanel.Position = [11 8 240 97];

            app.CFG_PORTLabel = uilabel(app.COMPanel);
            app.CFG_PORTLabel.Position = [7 48 71 22];
            app.CFG_PORTLabel.Text     = 'CFG_PORT';

            app.CfgPort = uieditfield(app.COMPanel, 'numeric');
            app.CfgPort.Limits              = [1 99];
            app.CfgPort.ValueChangedFcn     = createCallbackFcn(app, @CfgPortValueChanged, true);
            app.CfgPort.HorizontalAlignment = 'center';
            app.CfgPort.Tooltip             = {'User UART / Standard Port in Device Manager'};
            app.CfgPort.Position            = [93 48 33 22];
            app.CfgPort.Value               = 1;

            app.DATA_PORTLabel = uilabel(app.COMPanel);
            app.DATA_PORTLabel.Position = [7 18 76 22];
            app.DATA_PORTLabel.Text     = 'DATA_PORT';

            app.DatPort = uieditfield(app.COMPanel, 'numeric');
            app.DatPort.Limits              = [1 99];
            app.DatPort.ValueChangedFcn     = createCallbackFcn(app, @DatPortValueChanged, true);
            app.DatPort.HorizontalAlignment = 'center';
            app.DatPort.Tooltip             = {'Data / Enhanced Port in Device Manager'};
            app.DatPort.Position            = [93 18 33 22];
            app.DatPort.Value               = 1;

            app.TestConnectionButton = uibutton(app.COMPanel, 'push');
            app.TestConnectionButton.ButtonPushedFcn = ...
                createCallbackFcn(app, @TestConnectionButtonPushed, true);
            app.TestConnectionButton.Position = [132 48 102 22];
            app.TestConnectionButton.Text     = 'Test Connection';

            % Data panel (Play Back) – hidden by default
            app.DatPanel = uipanel(app.VisualizerModeButtonGroup);
            app.DatPanel.Title    = 'Select data log file for play back';
            app.DatPanel.Position = [278 8 240 97];
            app.DatPanel.Visible  = 'off';

            app.DatButton = uibutton(app.DatPanel, 'push');
            app.DatButton.ButtonPushedFcn = createCallbackFcn(app, @DatButtonPushed, true);
            app.DatButton.Icon     = 'folder_file_icon.png';
            app.DatButton.Position = [78 10 154 22];
            app.DatButton.Text     = 'Browse';

            app.DataFileLabel = uilabel(app.DatPanel);
            app.DataFileLabel.HorizontalAlignment = 'right';
            app.DataFileLabel.Position            = [9 48 54 22];
            app.DataFileLabel.Text                = 'Data File';

            app.DatPath = uieditfield(app.DatPanel, 'text');
            app.DatPath.ValueChangedFcn = createCallbackFcn(app, @DatPathValueChanged, true);
            app.DatPath.FontSize        = 10;
            app.DatPath.Tooltip         = {'Enter full path or use Browse.'};
            app.DatPath.Position        = [78 39 154 31];

            % ── Right Panel (empty – used only for GridLayout reflow) ──────
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row    = 1;
            app.RightPanel.Layout.Column = 2;

            % Show the figure
            app.SetupUIFigure.Visible = 'on';
        end
    end

    % ─────────────────────────────────────────────────────────────────────
    % App creation and deletion
    % ─────────────────────────────────────────────────────────────────────
    methods (Access = public)

        function app = setup_as_exported

            createComponents(app)
            registerApp(app, app.SetupUIFigure)

            % Carregar valores anteriores de state.mat (se existir)
            if exist('state.mat', 'file')
                try
                    S = load('state.mat');
                    if isfield(S, 'rect1')
                        app.Rect1XLeft.Value  = S.rect1.xLeft;
                        app.Rect1XRight.Value = S.rect1.xRight;
                        app.Rect1YNear.Value  = S.rect1.yNear;
                        app.Rect1YFar.Value   = S.rect1.yFar;
                    end
                    if isfield(S, 'rect2')
                        app.Rect2XLeft.Value  = S.rect2.xLeft;
                        app.Rect2XRight.Value = S.rect2.xRight;
                        app.Rect2YNear.Value  = S.rect2.yNear;
                        app.Rect2YFar.Value   = S.rect2.yFar;
                    end
                    if isfield(S, 'offset')
                        if isfield(S.offset, 'height'), app.MountingHeight.Value = S.offset.height; end
                        if isfield(S.offset, 'el'),     app.ElevationTilt.Value  = S.offset.el;     end
                    end
                    if isfield(S, 'comPort')
                        app.CfgPort.Value = S.comPort.cfg;
                        app.DatPort.Value = S.comPort.data;
                        app.comPort       = S.comPort;
                    end
                    if isfield(S, 'cfgFile') && ischar(S.cfgFile.name)
                        app.CfgPath.Value = [S.cfgFile.path S.cfgFile.name];
                        app.cfgFile       = S.cfgFile;
                    end
                catch
                end
            end

            % Block until the user clicks Setup Complete (closereq releases this)
            uiwait(app.SetupUIFigure)

            if nargout == 0
                clear app
            end
        end

        function delete(app)
            delete(app.SetupUIFigure)
        end
    end
end
