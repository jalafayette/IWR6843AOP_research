classdef setup_as_exported_desing_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        GridLayout                     matlab.ui.container.GridLayout
        RecordDataPanel                matlab.ui.container.Panel
        SavedirectoryEditField_2       matlab.ui.control.EditField
        SavedirectoryEditField_2Label  matlab.ui.control.Label
        BrowseButton_3                 matlab.ui.control.Button
        FilenameEditField              matlab.ui.control.EditField
        FilenameEditFieldLabel         matlab.ui.control.Label
        installationspecificationsPanel  matlab.ui.container.Panel
        CancelamEditField              matlab.ui.control.EditField
        CancelamEditFieldLabel         matlab.ui.control.Label
        AnglegrausEditField            matlab.ui.control.EditField
        AnglegrausEditFieldLabel       matlab.ui.control.Label
        HeightmEditField               matlab.ui.control.EditField
        HeightmEditFieldLabel          matlab.ui.control.Label
        AreaSelectionPanel             matlab.ui.container.Panel
        YFarmEditField_s               matlab.ui.control.EditField
        YNearmEditField_s              matlab.ui.control.EditField
        XRightmEditField_s             matlab.ui.control.EditField
        XLeftmEditField_s              matlab.ui.control.EditField
        SecurityLabel                  matlab.ui.control.Label
        updateButton                   matlab.ui.control.Button
        Trigger2Label                  matlab.ui.control.Label
        Trigger1Label                  matlab.ui.control.Label
        YFarmEditField_2               matlab.ui.control.EditField
        YNearmEditField_2              matlab.ui.control.EditField
        XRightmEditField_2             matlab.ui.control.EditField
        XLeftmEditField_2              matlab.ui.control.EditField
        YFarmEditField_1               matlab.ui.control.EditField
        YFarLabel                      matlab.ui.control.Label
        YNearmEditField_1              matlab.ui.control.EditField
        YNearLabel                     matlab.ui.control.Label
        XRightmEditField_1             matlab.ui.control.EditField
        XRightmEditFieldLabel          matlab.ui.control.Label
        XLeftmEditField_1              matlab.ui.control.EditField
        XLeftLabel                     matlab.ui.control.Label
        AreaCalibrationButton          matlab.ui.control.Button
        SetupCompleteButton            matlab.ui.control.Button
        SelectCFGFilePanel             matlab.ui.container.Panel
        BrowseButton_2                 matlab.ui.control.Button
        CFGFileEditField               matlab.ui.control.EditField
        CFGFileEditFieldLabel          matlab.ui.control.Label
        VisualiserModePanel            matlab.ui.container.Panel
        PlaybackButton                 matlab.ui.control.StateButton
        RealTimeButton                 matlab.ui.control.StateButton
        SelectdatalogfileforplaybackPanel  matlab.ui.container.Panel
        DatafileEditField              matlab.ui.control.EditField
        DatafileEditFieldLabel         matlab.ui.control.Label
        BrowseButton                   matlab.ui.control.Button
        SetCOMportPanel                matlab.ui.container.Panel
        DATA_PORTEditField             matlab.ui.control.EditField
        DATA_PORTEditFieldLabel        matlab.ui.control.Label
        CFG_PORTEditField              matlab.ui.control.EditField
        CFG_PORTEditFieldLabel         matlab.ui.control.Label
        TestConnectionButton           matlab.ui.control.Button
    end

    
    properties (Access = private)
        onePanelWidth = 576; 
    end     
    
    properties (Access = public)
        mode = 1;
        datFile = struct('name', [], 'path', []);
        cfgFile = struct('name', [], 'path', []);
        logFile = struct('name', [], 'path', []);
        offset  = struct('height', [], 'az', [], 'rot', []);
        comPort = struct('cfg', 1, 'data', 1, 'status', 0);
        
    end
   
    properties (Access = public)
        IsAccepted = false;
    end




    methods (Access = private)

        function sucesso = atualizarFicheiroCFG(app, caminhoCFG, altura, angulo_horizontal, tamanho_cancela, isCalib)
            sucesso = false;
         
        
            % Conversão e validação de tipos de entrada
            if ischar(altura)            || isstring(altura),            altura = str2double(altura); end
            if ischar(angulo_horizontal) || isstring(angulo_horizontal), angulo_horizontal = str2double(angulo_horizontal); end
            if ischar(tamanho_cancela)   || isstring(tamanho_cancela),   tamanho_cancela = str2double(tamanho_cancela); end
        
            % -------------------------------------------------------------
            % CÁLCULO DO maxRangeBin COM MARGEM DE SEGURANÇA
            % Resolução típica: ~0.0441m / bin
            
            % a ponta e a zona em redor são 100% detetadas sem corte FFT.
            % -------------------------------------------------------------
            rangeRes = 0.0703;
            margemSeguranca = 0.5; % +0.5 metro de margem além do comprimento da cancela
            alcanceTotal = tamanho_cancela + margemSeguranca;
            maxRangeBin = round(alcanceTotal / rangeRes);
        
            fid = fopen(char(caminhoCFG), 'r');
            if fid == -1
                errordlg('Não foi possível aceder ao ficheiro .cfg selecionado.', 'Erro');
                return;
            end
        
            linhas = {};
            while ~feof(fid)
                linha = fgetl(fid);
                if ischar(linha)
                    linhas{end+1} = linha;
                end
            end
            fclose(fid);
        
            zMin = -altura; 
            zMax = 3.0 - altura; 
        
            for i = 1:length(linhas)
                linhaAtual = strtrim(linhas{i});
        
                if startsWith(linhaAtual, 'sensorPosition')
                    linhas{i} = sprintf('sensorPosition 0 0 %.2f %.2f 0', altura, angulo_horizontal);
        
               % elseif startsWith(linhaAtual, 'heatmapGenCfg', 'IgnoreCase', true)
                   % tokens = strtrim(strsplit(linhaAtual));
                   % if numel(tokens) >= 6
                  %      tokens{6} = sprintf('%d', maxRangeBin); % Altera apenas o 5º parâmetro
                   %     linhas{i} = strjoin(tokens, ' ');
                   % end
        
                elseif isCalib
                    % --- CONFIGURAÇÃO PARA AREA_CALIBRATION.CFG ---
                    % Na calibração, abrimos a boundaryBox até à distância com margem
                    if startsWith(linhaAtual, 'boundaryBox') || startsWith(linhaAtual, 'staticBoundaryBox')
                        yMaxCalib = max(tamanho_cancela + 1.5, 6.0);
                        linhas{i} = sprintf('%s -5.00 5.00 0.00 %.2f %.2f %.2f', extractBefore(linhaAtual,' '), yMaxCalib, zMin, zMax);
                    end
                else
                    % --- CONFIGURAÇÃO PARA REAL_TIME.CFG ---
                    if exist('state.mat', 'file')
                        dados = load('state.mat');
                        
                        % --- Limites da Total Area ---
                        if isfield(dados.totalArea, 'vx')
                            xMinTotal = min(dados.totalArea.vx);
                            xMaxTotal = max(dados.totalArea.vx);
                            yMinTotal = min(dados.totalArea.vy);
                            yMaxTotal = max(dados.totalArea.vy);
                        else
                            xMinTotal = dados.totalArea.xLeft;
                            xMaxTotal = dados.totalArea.xRight;
                            yMinTotal = dados.totalArea.yNear;
                            yMaxTotal = dados.totalArea.yFar;
                        end

                        % --- Limites combinados das Zonas de Trigger e Segurança ---
                        allX = []; allY = [];
                        
                        % Processar Trigger Zones
                        if isfield(dados, 'triggerZones') && ~isempty(dados.triggerZones)
                            if isfield(dados.triggerZones, 'vx')
                                allX = [allX, dados.triggerZones.vx];
                                allY = [allY, dados.triggerZones.vy];
                            elseif isfield(dados.triggerZones, 'xLeft')
                                allX = [allX, [dados.triggerZones.xLeft], [dados.triggerZones.xRight]];
                                allY = [allY, [dados.triggerZones.yNear], [dados.triggerZones.yFar]];
                            end
                        end
                        
                        % Processar Safety Zones
                        if isfield(dados, 'safetyZones') && ~isempty(dados.safetyZones)
                            if isfield(dados.safetyZones, 'vx')
                                allX = [allX, dados.safetyZones.vx];
                                allY = [allY, dados.safetyZones.vy];
                            elseif isfield(dados.safetyZones, 'xLeft')
                                allX = [allX, [dados.safetyZones.xLeft], [dados.safetyZones.xRight]];
                                allY = [allY, [dados.safetyZones.yNear], [dados.safetyZones.yFar]];
                            end
                        end
                        
                        % Se existirem zonas definidas, calcula os limites; caso contrário usa a totalArea
                        if ~isempty(allX)
                            xMinStatic = min(allX);
                            xMaxStatic = max(allX);
                            yMinStatic = min(allY);
                            yMaxStatic = max(allY);
                        else
                            xMinStatic = xMinTotal;
                            xMaxStatic = xMaxTotal;
                            yMinStatic = yMinTotal;
                            yMaxStatic = yMaxTotal;
                        end

                        % Escrita no ficheiro .CFG
                        if startsWith(linhaAtual, 'boundaryBox')
                            linhas{i} = sprintf('boundaryBox %.2f %.2f %.2f %.2f %.2f %.2f', ...
                                xMinTotal, xMaxTotal, yMinTotal, yMaxTotal, zMin, zMax);
                        elseif startsWith(linhaAtual, 'staticBoundaryBox')
                            linhas{i} = sprintf('staticBoundaryBox %.2f %.2f %.2f %.2f %.2f %.2f', ...
                                xMinStatic, xMaxStatic, yMinStatic, yMaxStatic, zMin, zMax);
                        end
                    end
                end
            end
       
        
            fid = fopen(caminhoCFG, 'w');
            for i = 1:length(linhas)
                fprintf(fid, '%s\n', linhas{i});
            end
            fclose(fid);
            sucesso = true;
        end
         
           
              
        
       
        
        %função para guardar dados num ficheiro txt
        function  DatButtonPushed(app,~)
            [app.datFile.name, app.datFile.path] = uigetfile('*.txt', 'Select Log File');
            if ischar(app.datFile.name)
                app.DatPath.Value = [app.datFile.path app.datFile.name];
            end
            figure(app.SetupUIFigure);
        end
        
        %função para selecionar o ficheiro .cfg do sensor
        function CgfButtonPushed(app, ~)
            [app.cfgFile.name, app.cfgFile.path] = uigetfile('*.cfg', 'Select CFG File');
            if ischar(app.cfgFile.name)
                app.CfgPath.Value = [app.cfgFile.path app.cfgFile.name];
            end
            figure(app.SetupUIFigure);
        end
        
       %função para encontrar a pasta para guardar o .cfg  
        function LogButtonPushed(app,~)
            app.logFile.path = uigetdir('Select Folder to Save');
            if ischar(app.logFile.path)
                app.SavePath.Value = app.logFile.path;
            end
            figure(app.SetupUIFigure);
            
        end
        
        %função para para inserir o caminho do ficheiro .cfg
        function CfgPathValueChaged(app,~)
            [app.cfgFile.path, name, ext] = fileparts(app.CfgPath.Value);
            app.cfgFile.name = [name ext];
            
        end
        
        function DatPathValueChaged(app, ~)
            [app.datFile.path, name, ext] = fileparts(app.DatPath.Value);
            app.datFile.name = [name ext];
            
        end
        
        %função para guardar estado da comport CFG
        function CfgPortValueChanged(app, ~)
            app.comport.cfg = app.CfgPort.Value;
            app.broadcastSetupState();
        end

         %função para guardar estado da comport DATA
        function DatPortValueChaged(app, ~)
            app.comPort.data = app.DatPort.Value;
            app.broadcastSetupState();
        end
        
        %funcão para testar a comunicação das portas COM
        function TestConnectionButtonPushed(app, ~)
            
            hDataPort = initDataPort(app.DatPort.Value); % retorna -1 se a conexão das port COM falhar
            hCfgPort  = initCfgPort(app.CfgPort.Value);  %

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
        

        %função para abrir o plot de calibração das areas
        function CalibrationButtonPushed(app,~)
            % Process CfgPath the same way SetupComplete does
            [cPath, cName, cExt] = fileparts(app.CfgPath.Value);
            if ~isempty(cName)
                app.cfgFile.path = [cPath '\'];
                app.cfgFile.name = [cName cExt];
            end

            % Save port numbers, cfg path, and offset for calibration_plot
            cfgPortNum = app.CfgPort.Value;     
            datPortNum = app.DatPort.Value;      
            cfgFile    = app.cfgFile;            
            comStatus  = app.comPort.status;     
            offset_height = app.MountingHeight.Value; 
            offset_el     = app.ElevationTilt.Value;  
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
                    if isfield(S,'triggerZones') && numel(S.triggerZones) >= 1
                        app.XLeftmEditField_1.Value  = num2str(S.triggerZones(1).xLeft);
                        app.XRightmEditField_1.Value = num2str(S.triggerZones(1).xRight);
                        app.YNearmEditField_1.Value  = num2str(S.triggerZones(1).yNear);
                        app.YFarmEditField_1.Value   = num2str(S.triggerZones(1).yFar);
                    end
                    if isfield(S,'triggerZones') && numel(S.triggerZones) >= 2
                        app.XLeftmEditField_2.Value  = num2str(S.triggerZones(2).xLeft);
                        app.XRightmEditField_2.Value = num2str(S.triggerZones(2).xRight);
                        app.YNearmEditField_2.Value  = num2str(S.triggerZones(2).yNear);
                        app.YFarmEditField_2.Value   = num2str(S.triggerZones(2).yFar);
                    end
                    if isfield(S,'safetyZones') && ~isempty(S.safetyZones)
                        app.XLeftmEditField_s.Value  = num2str(S.safetyZones(1).xLeft);
                        app.XRightmEditField_s.Value = num2str(S.safetyZones(1).xRight);
                        app.YNearmEditField_s.Value  = num2str(S.safetyZones(1).yNear);
                        app.YFarmEditField_s.Value   = num2str(S.safetyZones(1).yFar);
                    end
                catch
                    % Silent – user can set fields manually
                end
            end

            % Show setup again
            app.SetupUIFigure.Visible = 'on';
            figure(app.SetupUIFigure);
        end

        %função para abrir o plot final
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
            REAL_TIME_MODE = app.RealTimeButton.Value; 
            ENABLE_RECORD  = app.EnableRecord.Value;   
            datFile = app.datFile; 
            cfgFile = app.cfgFile; 
            logFile = app.logFile; 
            offset  = app.offset;  
            comPort = app.comPort; 

            zones = struct( ...
                'enable',        app.EnableZones.Value, ...
                'criticalStart', app.CriticalStart.Value, ...
                'criticalEnd',   app.CriticalEnd.Value, ...
                'warnStart',     app.WarnStart.Value, ...
                'warnEnd',       app.WarnEnd.Value, ...
                'projTime',      app.ProjTime.Value); 

            % 3. Build rect structs with exact field names expected by visualizer
            rect1 = struct( ...
                'xLeft',  app.Rect1XLeft.Value, ...
                'xRight', app.Rect1XRight.Value, ...
                'yNear',  app.Rect1YNear.Value, ...
                'yFar',   app.Rect1YFar.Value); 

            rect2 = struct( ...
                'xLeft',  app.Rect2XLeft.Value, ...
                'xRight', app.Rect2XRight.Value, ...
                'yNear',  app.Rect2YNear.Value, ...
                'yFar',   app.Rect2YFar.Value);

            % 4. Save ALL variables the visualizer needs to disk
            save('state.mat', ...
                'REAL_TIME_MODE', 'ENABLE_RECORD', ...
                'datFile', 'cfgFile', 'logFile', 'offset', ...
                'comPort', 'zones', 'rect1', 'rect2');

            % 5. Close setup → releases uiwait in constructor
            closereq
        end
         
        
        %função para ativar ou desativar 
        function EnableZonesValueChanged(app,~)
            if app.EnableZones.Value, s = 'on'; else, s = 'off'; end
            app.CriticalStart.Enable = s;
            app.CriticalEnd.Enable   = s;
            app.WarnStart.Enable     = s;
            app.WarnEnd.Enable       = s;
            app.ProjTime.Enable      = s;
            
        end
        
        
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % Carrega o ficheiro se ele já existir de simulações anteriores
            if exist('state.mat', 'file')
                S = load('state.mat');
                
                % Preenche as caixas de texto com a configuração guardada
                % Nota: Garante que estes nomes coincidem com os teus componentes à direita
                app.CFG_PORTEditField.Value  = num2str(S.comPort.cfg);
                app.DATA_PORTEditField.Value = num2str(S.comPort.data);
                app.HeightmEditField.Value     = num2str(S.offset.height);
                app.AnglegrausEditField.Value = num2str(S.offset.az);
                
                if isfield(S, 'cfgFile')
                    app.cfgFile = fullfile(S.cfgFile.path, S.cfgFile.name);
                end
            end
        end

        % Button pushed function: TestConnectionButton
        function TestConnectionButtonPushed2(app, event)
            % 1. Tenta ler as caixas de texto e iniciar as portas
            hDataPort = initDataPort(app.DATA_PORTEditField.Value); 
            hCfgPort  = initCfgPort(app.CFG_PORTEditField.Value);
            
            try
                % ----------------------------------------------------------------─
                % TESTE DE ENTRADA: Se alguma porta for -1 ou inválida, 
                % o MATLAB falha aqui e o 'catch' captura o erro imediatamente!
                % ----------------------------------------------------------------─
                cfgStatus  = hCfgPort.Status;
                dataStatus = hDataPort.Status;
                
                % 2. Se passou o teste acima, as portas são objetos válidos!
                if strcmp(dataStatus, 'open') && hDataPort.BytesAvailable > 0
                    uialert(app.UIFigure, 'Device appears to already be running. Press NRST on the EVM.', 'Need to assert NRST');
                    app.comPort.status = -1;
                    return;
                else
                    if strcmp(cfgStatus, 'open')
                        fprintf(hCfgPort, 'version');
                        pause(0.5);
                        response = '';
                        
                        if hCfgPort.BytesAvailable > 0
                            for i = 1:10
                                if hCfgPort.BytesAvailable > 0
                                    rstr = fgets(hCfgPort);
                                    response = append(response, rstr);
                                end
                            end
                            uialert(app.UIFigure, response, 'Test successful: CFG Port Opened', 'icon', 'success');
                            app.comPort.status = 1;
                        else
                            uialert(app.UIFigure, 'Port opened but no response.', 'Issue with CFG Port');
                            app.comPort.status = -2;
                            fclose(hDataPort); fclose(hCfgPort);
                        end
                    else
                        uialert(app.UIFigure, 'Ports created but failed to open.', 'Ports Closed');
                        app.comPort.status = -2;
                    end
                end
                
            catch ME
                % ----------------------------------------------------------------─
                % O CATCH CAPTURA TUDO: "Dot indexing", "Invalid Object", etc.
                % ----------------------------------------------------------------─
                app.comPort.status = -2;
                
                % Mensagem amigável para o utilizador em vez do erro vermelho
                uialert(app.UIFigure, ...
                    ['Não foi possível estabelecer ligação. As portas estão em uso, ' ...
                     'foram fechadas pela calibração ou os números digitados estão incorretos.'], ...
                    'Erro de Conexão', 'icon', 'error');
                    
                disp(['[DEBUG] Erro capturado com segurança: ' ME.message]);
            end

            
        
        end

        % Button pushed function: BrowseButton_2
        function BrowseButton_2Pushed(app, event)
            app.cfgFile = struct('name', '', 'path', '');

            [app.cfgFile.name, app.cfgFile.path] = uigetfile('*.cfg', 'Select CFG File');
            if ischar(app.cfgFile.name)
                app.CFGFileEditField.Value = fullfile(app.cfgFile.path, app.cfgFile.name);
            end
            
            figure(app.UIFigure); % Devolve o foco à janela
        
        end

        % Button pushed function: BrowseButton
        function BrowseButtonPushed(app, event)
            app.datFile = struct('path', '', 'name', '');

            [app.datFile.name, app.datFile.path] = uigetfile('*.txt', 'Select Data File');   
            if ischar(app.datFile.name)
                % Atualiza a caixa de texto do teu design 
                app.DatafileEditField.Value = fullfile(app.datFile.path, app.datFile.name); 
            end
            figure(app.UIFigure); % Devolve o foco à janela
        end

        % Button pushed function: AreaCalibrationButton
        function AreaCalibrationButtonPushed(app, event)
            % 1. Extrair os valores básicos do UI
                cfgPortNum    = app.CFG_PORTEditField.Value;
                datPortNum    = app.DATA_PORTEditField.Value;
                cfgFile       = app.cfgFile;
                comStatus     = app.comPort.status;
                altura        = app.HeightmEditField.Value;     % Altura (Sensor Z)
                
                % --- NOVOS INPUTS DA CANCELA (Adapta para os nomes reais da tua UI) ---
                angulo_horizontal     = app.AnglegrausEditField.Value; % Ângulo Horizontal (Azimuth)
                tamanho_cancela   = app.CancelamEditField.Value;   % Comprimento da cancela em metros

                
            

                % 2. Definir o caminho absoluto para o ficheiro de CALIBRAÇÃO
                caminhoCalib = "C:\ti\radar_toolbox_4_00_00_05\source\ti\examples\Industrial_and_Personal_Electronics\Area_Scanner\chirp_configs\area_scanner_68xx_AOP_area_calibration.cfg"; 
                
                [calibPath, calibName, calibExt] = fileparts(caminhoCalib);
                cfgFile.path = [char(calibPath) '\'];
                cfgFile.name = [char(calibName) char(calibExt)];

                % 3. Chamar a função de escrita com os 6 parâmetros (isCalibration = true)
                app.atualizarFicheiroCFG(caminhoCalib, altura, angulo_horizontal, tamanho_cancela, true);
                
                rangeRes = 0.0703;
                maxRangeBin = round(str2double(tamanho_cancela) / rangeRes);


                % 4. Gravar estado temporário incluindo as novas variáveis para o calibration_plot.m
                save('temp_config.mat', 'cfgPortNum', 'datPortNum', 'cfgFile', 'comStatus', ...
                     'altura', 'angulo_horizontal', 'tamanho_cancela',"maxRangeBin");
                
                app.UIFigure.Visible = 'off';
                
                % 5. Lançar o modo calibração (rotina bloqueante)
                try
                    calibration_plot();
                    
                    if exist('state.mat', 'file')
                        S = load('state.mat');
                    
                        if isfield(S,'triggerZones') && numel(S.triggerZones) >= 1
                            app.XLeftmEditField_1.Value  = num2str(S.triggerZones(1).xLeft);
                            app.XRightmEditField_1.Value = num2str(S.triggerZones(1).xRight);
                            app.YNearmEditField_1.Value  = num2str(S.triggerZones(1).yNear);
                            app.YFarmEditField_1.Value   = num2str(S.triggerZones(1).yFar);
                        end
                        if isfield(S,'triggerZones') && numel(S.triggerZones) >= 2
                            app.XLeftmEditField_2.Value  = num2str(S.triggerZones(2).xLeft);
                            app.XRightmEditField_2.Value = num2str(S.triggerZones(2).xRight);
                            app.YNearmEditField_2.Value  = num2str(S.triggerZones(2).yNear);
                            app.YFarmEditField_2.Value   = num2str(S.triggerZones(2).yFar);
                        end
                        if isfield(S,'safetyZones') && ~isempty(S.safetyZones)
                            % Nota: Garante se o nome do teu componente termina em _Sec ou _s
                            app.XLeftmEditField_s.Value  = num2str(S.safetyZones(1).xLeft);
                            app.XRightmEditField_s.Value = num2str(S.safetyZones(1).xRight);
                            app.YNearmEditField_s.Value  = num2str(S.safetyZones(1).yNear);
                            app.YFarmEditField_s.Value   = num2str(S.safetyZones(1).yFar);
                        end
                    end
                catch ME
                    app.UIFigure.Visible = 'on';
                    uialert(app.UIFigure, ['Erro na calibração: ' ME.message], 'Erro');
                end
                
                % 6. Mostrar a UI de novo quando fechar
                figure(app.UIFigure);

        end

        % Button pushed function: SetupCompleteButton
        function SetupCompleteButtonPushed2(app, event)
            app.IsAccepted = true;
            
            altura    = app.HeightmEditField.Value;
            inclina   = app.AnglegrausEditField.Value;

            [cPath, cName, cExt] = fileparts(app.CFGFileEditField.Value);
            if ~isempty(cName)
                app.cfgFile.path = [cPath '\'];
                app.cfgFile.name = [cName cExt];
            end
            
            % --- CORREÇÃO AQUI: Recuperar e converter estritamente para Double ---
            angulo_horizontal = str2double(app.AnglegrausEditField.Value);
            gate_length       = str2double(app.CancelamEditField.Value);
            
            % Proteção caso os campos estejam vazios ou inválidos
            if isnan(angulo_horizontal), angulo_horizontal = 0; end
            if isnan(gate_length),       gate_length = 3.0; end
            
            % 1. Converter as restantes zonas
            t1_xleft  = str2double(app.XLeftmEditField_1.Value);
            t1_xRight = str2double(app.XRightmEditField_1.Value);
            t1_yNear  = str2double(app.YNearmEditField_1.Value);
            t1_yFar   = str2double(app.YFarmEditField_1.Value);
            
            t2_xleft  = str2double(app.XLeftmEditField_2.Value);
            t2_xRight = str2double(app.XRightmEditField_2.Value);
            t2_yNear  = str2double(app.YNearmEditField_2.Value);
            t2_yFar   = str2double(app.YFarmEditField_2.Value);
            
            sec_xleft  = str2double(app.XLeftmEditField_s.Value);
            sec_xRight = str2double(app.XRightmEditField_s.Value);
            sec_yNear  = str2double(app.YNearmEditField_s.Value);
            sec_yFar   = str2double(app.YFarmEditField_s.Value);
            
            % 2. Calcular o "Envelope" numérico real
            xMinStatic = min([t1_xleft, t2_xleft, sec_xleft]);
            xMaxStatic = max([t1_xRight, t2_xRight, sec_xRight]);
            yMinStatic = min([t1_yNear, t2_yNear, sec_yNear]);
            yMaxStatic = max([t1_yFar, t2_yFar, sec_yFar]);
            
            % 3. Obter o caminho do teu ficheiro .cfg de Tempo Real
            
            caminhoCalib = app.CFGFileEditField.Value;

            % 4. CORREÇÃO: Passar as variáveis corretas para a função
            app.atualizarFicheiroCFG(caminhoCalib, altura, angulo_horizontal, gate_length, false);
            
            % 5. Determinar o modo de operação
            if app.RealTimeButton.Value 
                REAL_TIME_MODE = 1;
                ENABLE_RECORD  = 1; 
            else
                REAL_TIME_MODE = 0;
                ENABLE_RECORD  = 0;
            end
        
            % 6. Construir objetos estruturados para o visualizador
            app.offset.height = altura;
            app.offset.az     = angulo_horizontal; 
            app.comPort.cfg   = app.CFG_PORTEditField.Value;
            app.comPort.data  = app.DATA_PORTEditField.Value;
            
            offset  = app.offset;
            comPort = app.comPort;
            cfgFile = app.cfgFile;
            datFile = app.datFile;
            logFile = app.logFile;
        
            triggerZones = struct('xLeft',{},'xRight',{},'yNear',{},'yFar',{},'lado',{});
            triggerZones(1) = struct('xLeft', t1_xleft, 'xRight', t1_xRight, ...
                                      'yNear', t1_yNear, 'yFar', t1_yFar, 'lado', 1);
            triggerZones(2) = struct('xLeft', t2_xleft, 'xRight', t2_xRight, ...
                                      'yNear', t2_yNear, 'yFar', t2_yFar, 'lado', 2);
            
            safetyZones = struct('xLeft', sec_xleft, 'xRight', sec_xRight, ...
                                  'yNear', sec_yNear, 'yFar', sec_yFar);
            
            % CORREÇÃO: O cálculo com 'sind' agora recebe doubles puros!
            gateTip = [gate_length * sind(angulo_horizontal), gate_length * cosd(angulo_horizontal)];
            
            rangeRes = 0.0703;
            maxRangeBin = round(gate_length / rangeRes);


            % Gravar tudo atualizado no state.mat
            save('state.mat', 'REAL_TIME_MODE', 'ENABLE_RECORD', 'datFile', 'cfgFile', ...
                 'logFile', 'offset', 'comPort', 'triggerZones', 'safetyZones', 'gateTip', 'gate_length','maxRangeBin', '-append');
        
            app.UIFigure.Visible = 'off';
            uiresume(app.UIFigure);
        end

        % Button pushed function: BrowseButton_3
        function BrowseButton_3Pushed(app, event)
            % uigetfile com o filtro '*.txt' garante que só aparecem ficheiros de texto
            [filename, pathname] = uigetfile('*.txt', 'Select Log File');
            
            % Se o utilizador não carregar em "Cancelar" (quando cancela, filename é 0)
            if ischar(filename)
                % 1. Atualiza os campos visíveis no teu ecrã automaticamente
                app.SavedirectoryEditField_2.Value = pathname;
                app.FilenameEditField.Value        = filename; 
                
                % 2. Guarda na estrutura interna do programa
                app.logFile.path = pathname;
                app.logFile.name = filename;
            end
            
            % Garante que a UI volta para a frente
            figure(app.UIFigure);
        end

        % Value changed function: RealTimeButton
        function RealTimeButtonPushed(app, event)
            app.SelectdatalogfileforplaybackPanel.Visible = "off";
            app.SetCOMportPanel.Visible = "on";
            app.RecordDataPanel.Visible = "on";
            app.PlaybackButton.Value == false;
        end

        % Value changed function: PlaybackButton
        function PlaybackButtonPushed(app, event)
            app.SelectdatalogfileforplaybackPanel.Visible = "on";
            app.SetCOMportPanel.Visible = "off";
            app.RecordDataPanel.Visible = "off";
            app.RealTimeButton.Value == false;
        end

        % Button pushed function: updateButton
        function updateButtonPushed(app, event)
            S = load('state.mat');

            if isfield(S,'triggerZones') && numel(S.triggerZones) >= 1
                app.XLeftmEditField_1.Value  = num2str(S.triggerZones(1).xLeft);
                app.XRightmEditField_1.Value = num2str(S.triggerZones(1).xRight);
                app.YNearmEditField_1.Value  = num2str(S.triggerZones(1).yNear);
                app.YFarmEditField_1.Value   = num2str(S.triggerZones(1).yFar);
            end
            if isfield(S,'triggerZones') && numel(S.triggerZones) >= 2
                app.XLeftmEditField_2.Value  = num2str(S.triggerZones(2).xLeft);
                app.XRightmEditField_2.Value = num2str(S.triggerZones(2).xRight);
                app.YNearmEditField_2.Value  = num2str(S.triggerZones(2).yNear);
                app.YFarmEditField_2.Value   = num2str(S.triggerZones(2).yFar);
            end
            if isfield(S,'safetyZones') && ~isempty(S.safetyZones)
                app.XLeftmEditField_s.Value  = num2str(S.safetyZones(1).xLeft);
                app.XRightmEditField_s.Value = num2str(S.safetyZones(1).xRight);
                app.YNearmEditField_s.Value  = num2str(S.safetyZones(1).yNear);
                app.YFarmEditField_s.Value   = num2str(S.safetyZones(1).yFar);
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'MATLAB App';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {150, 150, 150, '1x'};
            app.GridLayout.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};

            % Create VisualiserModePanel
            app.VisualiserModePanel = uipanel(app.GridLayout);
            app.VisualiserModePanel.Title = 'Visualiser Mode';
            app.VisualiserModePanel.Layout.Row = [1 3];
            app.VisualiserModePanel.Layout.Column = [1 4];

            % Create SetCOMportPanel
            app.SetCOMportPanel = uipanel(app.VisualiserModePanel);
            app.SetCOMportPanel.Title = 'Set COM port';
            app.SetCOMportPanel.Position = [9 8 299 101];

            % Create TestConnectionButton
            app.TestConnectionButton = uibutton(app.SetCOMportPanel, 'push');
            app.TestConnectionButton.ButtonPushedFcn = createCallbackFcn(app, @TestConnectionButtonPushed2, true);
            app.TestConnectionButton.Position = [144 14 142 54];
            app.TestConnectionButton.Text = 'Test Connection';

            % Create CFG_PORTEditFieldLabel
            app.CFG_PORTEditFieldLabel = uilabel(app.SetCOMportPanel);
            app.CFG_PORTEditFieldLabel.HorizontalAlignment = 'right';
            app.CFG_PORTEditFieldLabel.Position = [10 46 70 22];
            app.CFG_PORTEditFieldLabel.Text = 'CFG_PORT';

            % Create CFG_PORTEditField
            app.CFG_PORTEditField = uieditfield(app.SetCOMportPanel, 'text');
            app.CFG_PORTEditField.Position = [100 46 24 22];

            % Create DATA_PORTEditFieldLabel
            app.DATA_PORTEditFieldLabel = uilabel(app.SetCOMportPanel);
            app.DATA_PORTEditFieldLabel.HorizontalAlignment = 'right';
            app.DATA_PORTEditFieldLabel.Position = [10 14 75 22];
            app.DATA_PORTEditFieldLabel.Text = 'DATA_PORT';

            % Create DATA_PORTEditField
            app.DATA_PORTEditField = uieditfield(app.SetCOMportPanel, 'text');
            app.DATA_PORTEditField.Position = [100 14 24 22];

            % Create SelectdatalogfileforplaybackPanel
            app.SelectdatalogfileforplaybackPanel = uipanel(app.VisualiserModePanel);
            app.SelectdatalogfileforplaybackPanel.Title = 'Select data log file for play back';
            app.SelectdatalogfileforplaybackPanel.Position = [322 8 285 101];

            % Create BrowseButton
            app.BrowseButton = uibutton(app.SelectdatalogfileforplaybackPanel, 'push');
            app.BrowseButton.ButtonPushedFcn = createCallbackFcn(app, @BrowseButtonPushed, true);
            app.BrowseButton.Position = [90 12 159 23];
            app.BrowseButton.Text = 'Browse';

            % Create DatafileEditFieldLabel
            app.DatafileEditFieldLabel = uilabel(app.SelectdatalogfileforplaybackPanel);
            app.DatafileEditFieldLabel.HorizontalAlignment = 'right';
            app.DatafileEditFieldLabel.Position = [21 50 49 22];
            app.DatafileEditFieldLabel.Text = 'Data file';

            % Create DatafileEditField
            app.DatafileEditField = uieditfield(app.SelectdatalogfileforplaybackPanel, 'text');
            app.DatafileEditField.Position = [81 39 180 33];

            % Create RealTimeButton
            app.RealTimeButton = uibutton(app.VisualiserModePanel, 'state');
            app.RealTimeButton.ValueChangedFcn = createCallbackFcn(app, @RealTimeButtonPushed, true);
            app.RealTimeButton.Text = 'Real Time';
            app.RealTimeButton.Position = [15 117 280 23];

            % Create PlaybackButton
            app.PlaybackButton = uibutton(app.VisualiserModePanel, 'state');
            app.PlaybackButton.ValueChangedFcn = createCallbackFcn(app, @PlaybackButtonPushed, true);
            app.PlaybackButton.Text = 'Playback';
            app.PlaybackButton.Position = [335 117 256 23];

            % Create SelectCFGFilePanel
            app.SelectCFGFilePanel = uipanel(app.GridLayout);
            app.SelectCFGFilePanel.Title = 'Select CFG File';
            app.SelectCFGFilePanel.Layout.Row = 4;
            app.SelectCFGFilePanel.Layout.Column = [1 4];

            % Create CFGFileEditFieldLabel
            app.CFGFileEditFieldLabel = uilabel(app.SelectCFGFilePanel);
            app.CFGFileEditFieldLabel.HorizontalAlignment = 'right';
            app.CFGFileEditFieldLabel.Position = [21 3 53 22];
            app.CFGFileEditFieldLabel.Text = 'CFG File';

            % Create CFGFileEditField
            app.CFGFileEditField = uieditfield(app.SelectCFGFilePanel, 'text');
            app.CFGFileEditField.Position = [89 4 330 21];

            % Create BrowseButton_2
            app.BrowseButton_2 = uibutton(app.SelectCFGFilePanel, 'push');
            app.BrowseButton_2.ButtonPushedFcn = createCallbackFcn(app, @BrowseButton_2Pushed, true);
            app.BrowseButton_2.Position = [426 4 179 21];
            app.BrowseButton_2.Text = 'Browse';

            % Create SetupCompleteButton
            app.SetupCompleteButton = uibutton(app.GridLayout, 'push');
            app.SetupCompleteButton.ButtonPushedFcn = createCallbackFcn(app, @SetupCompleteButtonPushed2, true);
            app.SetupCompleteButton.Layout.Row = 8;
            app.SetupCompleteButton.Layout.Column = [3 4];
            app.SetupCompleteButton.Text = 'Setup Complete';

            % Create AreaCalibrationButton
            app.AreaCalibrationButton = uibutton(app.GridLayout, 'push');
            app.AreaCalibrationButton.ButtonPushedFcn = createCallbackFcn(app, @AreaCalibrationButtonPushed, true);
            app.AreaCalibrationButton.Layout.Row = 8;
            app.AreaCalibrationButton.Layout.Column = [1 2];
            app.AreaCalibrationButton.Text = 'Area Calibration';

            % Create AreaSelectionPanel
            app.AreaSelectionPanel = uipanel(app.GridLayout);
            app.AreaSelectionPanel.Title = 'Area Selection';
            app.AreaSelectionPanel.Layout.Row = [5 7];
            app.AreaSelectionPanel.Layout.Column = [2 3];

            % Create XLeftLabel
            app.XLeftLabel = uilabel(app.AreaSelectionPanel);
            app.XLeftLabel.HorizontalAlignment = 'right';
            app.XLeftLabel.Position = [21 93 63 22];
            app.XLeftLabel.Text = 'X Left [m]  ';

            % Create XLeftmEditField_1
            app.XLeftmEditField_1 = uieditfield(app.AreaSelectionPanel, 'text');
            app.XLeftmEditField_1.Position = [98 93 37 22];

            % Create XRightmEditFieldLabel
            app.XRightmEditFieldLabel = uilabel(app.AreaSelectionPanel);
            app.XRightmEditFieldLabel.HorizontalAlignment = 'right';
            app.XRightmEditFieldLabel.Position = [20 65 64 22];
            app.XRightmEditFieldLabel.Text = 'X Right [m]';

            % Create XRightmEditField_1
            app.XRightmEditField_1 = uieditfield(app.AreaSelectionPanel, 'text');
            app.XRightmEditField_1.Position = [98 65 37 22];

            % Create YNearLabel
            app.YNearLabel = uilabel(app.AreaSelectionPanel);
            app.YNearLabel.HorizontalAlignment = 'right';
            app.YNearLabel.Position = [20 36 65 22];
            app.YNearLabel.Text = 'Y Near [m] ';

            % Create YNearmEditField_1
            app.YNearmEditField_1 = uieditfield(app.AreaSelectionPanel, 'text');
            app.YNearmEditField_1.Position = [98 36 37 22];

            % Create YFarLabel
            app.YFarLabel = uilabel(app.AreaSelectionPanel);
            app.YFarLabel.HorizontalAlignment = 'right';
            app.YFarLabel.Position = [22 10 64 22];
            app.YFarLabel.Text = 'Y Far [m]   ';

            % Create YFarmEditField_1
            app.YFarmEditField_1 = uieditfield(app.AreaSelectionPanel, 'text');
            app.YFarmEditField_1.Position = [98 10 37 22];

            % Create XLeftmEditField_2
            app.XLeftmEditField_2 = uieditfield(app.AreaSelectionPanel, 'text');
            app.XLeftmEditField_2.Position = [162 93 37 22];

            % Create XRightmEditField_2
            app.XRightmEditField_2 = uieditfield(app.AreaSelectionPanel, 'text');
            app.XRightmEditField_2.Position = [162 65 37 22];

            % Create YNearmEditField_2
            app.YNearmEditField_2 = uieditfield(app.AreaSelectionPanel, 'text');
            app.YNearmEditField_2.Position = [162 36 39 22];

            % Create YFarmEditField_2
            app.YFarmEditField_2 = uieditfield(app.AreaSelectionPanel, 'text');
            app.YFarmEditField_2.Position = [162 10 39 22];

            % Create Trigger1Label
            app.Trigger1Label = uilabel(app.AreaSelectionPanel);
            app.Trigger1Label.Position = [89 118 61 22];
            app.Trigger1Label.Text = 'Trigger (1)';

            % Create Trigger2Label
            app.Trigger2Label = uilabel(app.AreaSelectionPanel);
            app.Trigger2Label.Position = [160 117 61 22];
            app.Trigger2Label.Text = 'Trigger (2)';

            % Create updateButton
            app.updateButton = uibutton(app.AreaSelectionPanel, 'push');
            app.updateButton.ButtonPushedFcn = createCallbackFcn(app, @updateButtonPushed, true);
            app.updateButton.Position = [6 116 80 25];
            app.updateButton.Text = 'update';

            % Create SecurityLabel
            app.SecurityLabel = uilabel(app.AreaSelectionPanel);
            app.SecurityLabel.Position = [231 117 48 22];
            app.SecurityLabel.Text = 'Security';

            % Create XLeftmEditField_s
            app.XLeftmEditField_s = uieditfield(app.AreaSelectionPanel, 'text');
            app.XLeftmEditField_s.Position = [231 93 37 22];

            % Create XRightmEditField_s
            app.XRightmEditField_s = uieditfield(app.AreaSelectionPanel, 'text');
            app.XRightmEditField_s.Position = [230 65 37 22];

            % Create YNearmEditField_s
            app.YNearmEditField_s = uieditfield(app.AreaSelectionPanel, 'text');
            app.YNearmEditField_s.Position = [230 36 37 22];

            % Create YFarmEditField_s
            app.YFarmEditField_s = uieditfield(app.AreaSelectionPanel, 'text');
            app.YFarmEditField_s.Position = [230 10 37 22];

            % Create installationspecificationsPanel
            app.installationspecificationsPanel = uipanel(app.GridLayout);
            app.installationspecificationsPanel.Title = 'installation specifications';
            app.installationspecificationsPanel.Layout.Row = [5 7];
            app.installationspecificationsPanel.Layout.Column = 4;

            % Create HeightmEditFieldLabel
            app.HeightmEditFieldLabel = uilabel(app.installationspecificationsPanel);
            app.HeightmEditFieldLabel.HorizontalAlignment = 'right';
            app.HeightmEditFieldLabel.Position = [4 98 61 22];
            app.HeightmEditFieldLabel.Text = 'Height (m)';

            % Create HeightmEditField
            app.HeightmEditField = uieditfield(app.installationspecificationsPanel, 'text');
            app.HeightmEditField.Position = [75 98 52 22];

            % Create AnglegrausEditFieldLabel
            app.AnglegrausEditFieldLabel = uilabel(app.installationspecificationsPanel);
            app.AnglegrausEditFieldLabel.HorizontalAlignment = 'right';
            app.AnglegrausEditFieldLabel.Position = [3 21 77 22];
            app.AnglegrausEditFieldLabel.Text = 'Angle (graus)';

            % Create AnglegrausEditField
            app.AnglegrausEditField = uieditfield(app.installationspecificationsPanel, 'text');
            app.AnglegrausEditField.Position = [84 21 41 22];

            % Create CancelamEditFieldLabel
            app.CancelamEditFieldLabel = uilabel(app.installationspecificationsPanel);
            app.CancelamEditFieldLabel.HorizontalAlignment = 'right';
            app.CancelamEditFieldLabel.Position = [1 57 70 22];
            app.CancelamEditFieldLabel.Text = 'Cancela (m)';

            % Create CancelamEditField
            app.CancelamEditField = uieditfield(app.installationspecificationsPanel, 'text');
            app.CancelamEditField.Position = [75 57 49 22];

            % Create RecordDataPanel
            app.RecordDataPanel = uipanel(app.GridLayout);
            app.RecordDataPanel.Title = 'Record Data';
            app.RecordDataPanel.Layout.Row = [5 7];
            app.RecordDataPanel.Layout.Column = 1;

            % Create FilenameEditFieldLabel
            app.FilenameEditFieldLabel = uilabel(app.RecordDataPanel);
            app.FilenameEditFieldLabel.HorizontalAlignment = 'right';
            app.FilenameEditFieldLabel.Position = [15 119 55 22];
            app.FilenameEditFieldLabel.Text = 'File name';

            % Create FilenameEditField
            app.FilenameEditField = uieditfield(app.RecordDataPanel, 'text');
            app.FilenameEditField.Position = [6 98 135 21];

            % Create BrowseButton_3
            app.BrowseButton_3 = uibutton(app.RecordDataPanel, 'push');
            app.BrowseButton_3.ButtonPushedFcn = createCallbackFcn(app, @BrowseButton_3Pushed, true);
            app.BrowseButton_3.Position = [15 10 118 33];
            app.BrowseButton_3.Text = 'Browse';

            % Create SavedirectoryEditField_2Label
            app.SavedirectoryEditField_2Label = uilabel(app.RecordDataPanel);
            app.SavedirectoryEditField_2Label.HorizontalAlignment = 'right';
            app.SavedirectoryEditField_2Label.Position = [9 72 82 22];
            app.SavedirectoryEditField_2Label.Text = 'Save directory';

            % Create SavedirectoryEditField_2
            app.SavedirectoryEditField_2 = uieditfield(app.RecordDataPanel, 'text');
            app.SavedirectoryEditField_2.Position = [9 52 132 21];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = setup_as_exported_desing_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end